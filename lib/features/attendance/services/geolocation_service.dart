import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/attendance_constants.dart';
import '../../../core/utils/haversine.dart';

/// 定位坐标
class GeoCoords {
  final double lat;
  final double lng;

  const GeoCoords({required this.lat, required this.lng});
}

/// 高德 IP 定位返回
class AmapIpLocationData {
  final GeoCoords coords;
  final String address;

  const AmapIpLocationData({required this.coords, required this.address});
}

/// 定位状态
class GeolocationState {
  final String location;
  final bool isGettingLocation;
  final bool isWithinRange;
  final bool isApproximateLocation;
  final GeoCoords lastCoords;

  const GeolocationState({
    this.location = '正在获取位置...',
    this.isGettingLocation = false,
    this.isWithinRange = true,
    this.isApproximateLocation = true,
    this.lastCoords = const GeoCoords(lat: 0, lng: 0),
  });

  GeolocationState copyWith({
    String? location,
    bool? isGettingLocation,
    bool? isWithinRange,
    bool? isApproximateLocation,
    GeoCoords? lastCoords,
  }) => GeolocationState(
    location: location ?? this.location,
    isGettingLocation: isGettingLocation ?? this.isGettingLocation,
    isWithinRange: isWithinRange ?? this.isWithinRange,
    isApproximateLocation: isApproximateLocation ?? this.isApproximateLocation,
    lastCoords: lastCoords ?? this.lastCoords,
  );
}

/// 定位异常
class LocationFailure implements Exception {
  final String message;
  final bool retryable;

  const LocationFailure(this.message, {this.retryable = false});

  @override
  String toString() => message;
}

/// 定位服务
/// 优先使用原生高精度坐标（高德 SDK / CoreLocation），并通过高德逆地理接口解析地址。
class GeolocationNotifier extends StateNotifier<GeolocationState> {
  static const MethodChannel _locationChannel = MethodChannel('oa/location');
  final Dio _dio;

  GeolocationNotifier(this._dio) : super(const GeolocationState());

  Future<dynamic> _invokeLocationMethod(
    String method, {
    dynamic arguments,
    String? fallbackMessage,
  }) async {
    try {
      return await _locationChannel.invokeMethod<dynamic>(method, arguments);
    } on MissingPluginException {
      throw LocationFailure(
        fallbackMessage ?? '当前平台暂不支持定位能力',
        retryable: false,
      );
    } on PlatformException catch (e) {
      final code = e.code;
      final message = _normalizeText(e.message);
      if (code == 'PERMISSION_DENIED') {
        throw LocationFailure(
          message.isNotEmpty ? message : '定位权限不足，请在系统设置中开启',
          retryable: false,
        );
      }
      if (code == 'SERVICE_DISABLED') {
        throw LocationFailure(
          message.isNotEmpty ? message : '定位服务未开启，请先开启定位服务',
          retryable: false,
        );
      }
      if (code == 'REQUEST_IN_PROGRESS') {
        throw LocationFailure(
          message.isNotEmpty ? message : '定位请求进行中，请稍后重试',
          retryable: true,
        );
      }
      if (code == 'LOCATION_TIMEOUT') {
        throw LocationFailure(
          message.isNotEmpty ? message : '定位超时，请稍后重试',
          retryable: true,
        );
      }
      throw LocationFailure(
        message.isNotEmpty ? message : (fallbackMessage ?? '定位失败，请稍后重试'),
        retryable: true,
      );
    }
  }

  Future<GeoCoords> _getDeviceCoords() async {
    if (kIsWeb) {
      throw const LocationFailure('Web 端暂不支持原生定位', retryable: false);
    }

    final serviceEnabled = await _invokeLocationMethod(
      'isLocationServiceEnabled',
      fallbackMessage: '无法读取定位服务状态',
    );
    if (serviceEnabled != true) {
      throw const LocationFailure('定位服务未开启，请先开启后重试', retryable: false);
    }

    String permission = _normalizeText(
      await _invokeLocationMethod('checkPermission', fallbackMessage: '权限检查失败'),
    );
    if (permission != 'granted') {
      permission = _normalizeText(
        await _invokeLocationMethod('requestPermission', fallbackMessage: '请求定位权限失败'),
      );
    }
    if (permission != 'granted') {
      throw const LocationFailure('定位权限不足，请在系统设置中开启', retryable: false);
    }

    final result = await _invokeLocationMethod(
      'getCurrentPosition',
      fallbackMessage: '定位失败，请稍后重试',
    );

    if (result is! Map) {
      throw const LocationFailure('定位数据格式异常，请稍后重试', retryable: true);
    }

    final lat = _toDouble(result['lat']);
    final lng = _toDouble(result['lng']);
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      throw const LocationFailure('定位数据无效，请稍后重试', retryable: true);
    }

    return GeoCoords(lat: lat, lng: lng);
  }

  Future<String> _reverseGeocodeFromAmap(
    GeoCoords coords, {
    Duration? timeout,
  }) async {
    Future<String> request() async {
      final response = await _dio.get(
        'https://restapi.amap.com/v3/geocode/regeo',
        queryParameters: {
          'key': AttendanceConstants.amapKey,
          'location': '${coords.lng},${coords.lat}',
          'extensions': 'base',
        },
      );
      final data = response.data;
      if (data is! Map || data['status'] != '1') {
        throw const LocationFailure('逆地理解析失败', retryable: true);
      }

      final regeocode = data['regeocode'];
      if (regeocode is! Map) {
        throw const LocationFailure('逆地理解析失败', retryable: true);
      }

      final formatted = _normalizeText(regeocode['formatted_address']);
      if (formatted.isNotEmpty) return formatted;

      final component = regeocode['addressComponent'];
      if (component is Map) {
        final province = _normalizeText(component['province']);
        final city = _normalizeText(component['city']);
        final district = _normalizeText(component['district']);
        final township = _normalizeText(component['township']);
        final street = component['streetNumber'] is Map
            ? _normalizeText((component['streetNumber'] as Map)['street'])
            : '';
        final address = [
          if (province.isNotEmpty) province,
          if (city.isNotEmpty && city != province) city,
          if (district.isNotEmpty) district,
          if (township.isNotEmpty) township,
          if (street.isNotEmpty) street,
        ].join();
        if (address.isNotEmpty) return address;
      }

      throw const LocationFailure('逆地理解析失败', retryable: true);
    }

    try {
      if (timeout == null) {
        return await request();
      }

      try {
        return await request().timeout(
          timeout,
          onTimeout: () =>
              throw const LocationFailure('地址解析超时，请稍后重试', retryable: true),
        );
      } on LocationFailure catch (e) {
        // 短超时场景下给一次不加短超时的重试机会，尽量拿到具体地址
        if (e.message.contains('超时')) {
          return await request();
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[geolocation_service] regeo error: $e');
      // 地址解析失败不影响围栏判定，兜底返回粗略地址，避免界面显示经纬度
      try {
        final ipData = await _getIpLocationFromAmap();
        if (ipData.address.isNotEmpty) return '${ipData.address}(地址近似)';
      } catch (_) {}
      return '地址解析失败';
    }
  }

  Future<AmapIpLocationData> _getIpLocationFromAmap() async {
    final url =
        'https://restapi.amap.com/v3/ip?key=${AttendanceConstants.amapKey}';
    final response = await _dio.get(url);
    final data = response.data;

    if (data is! Map || data['status'] != '1') {
      throw const LocationFailure('高德定位失败，请稍后重试', retryable: true);
    }

    final province = _normalizeText(data['province']);
    final city = _normalizeText(data['city']);
    final district = _normalizeText(data['district']);
    final rectangle = _normalizeText(data['rectangle']);

    final displayCity = (city.isEmpty || city == '[]') ? province : city;
    final address = [
      if (province.isNotEmpty) province,
      if (displayCity.isNotEmpty && displayCity != province) displayCity,
      if (district.isNotEmpty) district,
    ].join();

    final coords = _parseRectangleCenter(rectangle);

    return AmapIpLocationData(
      coords: coords ?? const GeoCoords(lat: 0, lng: 0),
      address: address.isNotEmpty ? address : '高德定位成功',
    );
  }

  GeoCoords? _parseRectangleCenter(String rectangle) {
    if (rectangle.isEmpty || !rectangle.contains(';')) return null;
    final points = rectangle.split(';');
    if (points.length != 2) return null;

    final p1 = points[0].split(',');
    final p2 = points[1].split(',');
    if (p1.length != 2 || p2.length != 2) return null;

    final lng1 = _toDouble(p1[0]);
    final lat1 = _toDouble(p1[1]);
    final lng2 = _toDouble(p2[0]);
    final lat2 = _toDouble(p2[1]);
    if (lng1 == null || lat1 == null || lng2 == null || lat2 == null) {
      return null;
    }

    return GeoCoords(lat: (lat1 + lat2) / 2, lng: (lng1 + lng2) / 2);
  }

  String _normalizeText(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  /// 获取当前位置（优先精确定位，失败时降级高德 IP 定位）
  Future<String> getCurrentLocation({
    int retryCount = 0,
    Duration? addressTimeout,
  }) async {
    state = state.copyWith(
      isGettingLocation: true,
      location: '正在通过高德定位...',
    );

    try {
      final coords = await _getDeviceCoords();
      final address = await _reverseGeocodeFromAmap(
        coords,
        timeout: addressTimeout,
      );
      state = state.copyWith(
        isGettingLocation: false,
        location: address,
        isApproximateLocation: false,
        lastCoords: coords,
      );
      return address;
    } catch (e) {
      debugPrint('[geolocation_service] Error: $e');
      var error = e is LocationFailure
          ? e
          : const LocationFailure('高德定位失败，请稍后重试', retryable: true);

      // 仅在精确定位暂时不可用时降级到高德 IP 定位，避免打卡流程被完全阻断
      if (error.retryable || kIsWeb) {
        try {
          Future<AmapIpLocationData> request() => _getIpLocationFromAmap();
          final locationData = addressTimeout == null
              ? await request()
              : await request().timeout(
                  addressTimeout,
                  onTimeout: () => throw const LocationFailure(
                    '高德定位超时，请稍后重试',
                    retryable: true,
                  ),
                );
          state = state.copyWith(
            isGettingLocation: false,
            location: '${locationData.address}(粗略定位)',
            isApproximateLocation: true,
            lastCoords: locationData.coords,
          );
          return locationData.address;
        } catch (fallbackError) {
          debugPrint('[geolocation_service] ip fallback error: $fallbackError');
          error = fallbackError is LocationFailure
              ? fallbackError
              : const LocationFailure('高德定位失败，请稍后重试', retryable: true);
        }
      }

      if (error.retryable &&
          retryCount < AttendanceConstants.maxLocationRetries) {
        state = state.copyWith(
          location:
              '定位失败，正在重试 (${retryCount + 1}/${AttendanceConstants.maxLocationRetries})...',
        );
        await Future.delayed(const Duration(seconds: 2));
        return getCurrentLocation(
          retryCount: retryCount + 1,
          addressTimeout: addressTimeout,
        );
      }

      state = state.copyWith(location: error.message, isGettingLocation: false);
      return '位置获取失败';
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 检查是否在围栏范围内
  void checkWithinRange(double fenceLat, double fenceLng, int radius) {
    // 高德 IP 定位是城市级别近似位置，无法进行米级围栏判断，默认视为范围内。
    if (state.isApproximateLocation) {
      state = state.copyWith(isWithinRange: true);
      return;
    }

    final coords = state.lastCoords;
    if (fenceLat == 0 || fenceLng == 0 || coords.lat == 0 || coords.lng == 0) {
      state = state.copyWith(isWithinRange: true);
      return;
    }
    final dist = haversineDistance(coords.lat, coords.lng, fenceLat, fenceLng);
    state = state.copyWith(isWithinRange: dist <= radius);
  }
}

/// 定位服务 Provider
final geolocationProvider =
    StateNotifierProvider<GeolocationNotifier, GeolocationState>((ref) {
      // 使用独立的 Dio 实例（不走业务拦截器，直接请求高德 API）
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return GeolocationNotifier(dio);
    });
