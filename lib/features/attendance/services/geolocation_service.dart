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

/// 原生定位返回
class NativeLocationData {
  final GeoCoords coords;

  const NativeLocationData({required this.coords});
}

/// 定位状态
class GeolocationState {
  final String location;
  final bool isGettingLocation;
  final bool isWithinRange;
  final GeoCoords lastCoords;

  const GeolocationState({
    this.location = '正在获取位置...',
    this.isGettingLocation = false,
    this.isWithinRange = true,
    this.lastCoords = const GeoCoords(lat: 0, lng: 0),
  });

  GeolocationState copyWith({
    String? location,
    bool? isGettingLocation,
    bool? isWithinRange,
    GeoCoords? lastCoords,
  }) =>
      GeolocationState(
        location: location ?? this.location,
        isGettingLocation: isGettingLocation ?? this.isGettingLocation,
        isWithinRange: isWithinRange ?? this.isWithinRange,
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

/// 定位服务 - 对应 src/composables/useGeolocation.ts
/// 使用原生 MethodChannel 获取 GPS + 高德逆地理编码
class GeolocationNotifier extends StateNotifier<GeolocationState> {
  final Dio _dio;
  static const MethodChannel _locationChannel = MethodChannel('oa/location');

  GeolocationNotifier(this._dio) : super(const GeolocationState());

  /// 高德逆地理编码
  Future<String> _reverseGeocoding(double lat, double lng) async {
    final url =
        'https://restapi.amap.com/v3/geocode/regeo?key=${AttendanceConstants.amapKey}'
        '&location=$lng,$lat&poitype=&radius=100&extensions=all&batch=false&roadlevel=0';
    try {
      final response = await _dio.get(url);
      final data = response.data;
      if (data is Map && data['status'] == '1' && data['regeocode'] != null) {
        final regeocode = data['regeocode'];
        final formattedAddress = regeocode['formatted_address'];
        if (formattedAddress is String && formattedAddress.isNotEmpty) {
          return formattedAddress;
        }
        final ac = regeocode['addressComponent'];
        if (ac is Map) {
          final parts = <String>[];
          if (ac['province'] != null) parts.add(ac['province'].toString());
          if (ac['city'] != null &&
              ac['city'].toString() != ac['province'].toString()) {
            parts.add(ac['city'].toString());
          }
          if (ac['district'] != null) parts.add(ac['district'].toString());
          if (ac['township'] != null) parts.add(ac['township'].toString());
          if (parts.isNotEmpty) return parts.join('');
        }
      }
      return 'GPS: $lat, $lng';
    } catch (e) {
      debugPrint('[geolocation_service] Error: $e');
      return 'GPS: $lat, $lng';
    }
  }

  /// 获取当前位置
  Future<String> getCurrentLocation({int retryCount = 0}) async {
    state = state.copyWith(
      isGettingLocation: true,
      location: '正在获取GPS位置...',
    );

    try {
      final locationData = await _getLocationData();
      state = state.copyWith(lastCoords: locationData.coords);

      final amapAddress = await _reverseGeocoding(
        locationData.coords.lat,
        locationData.coords.lng,
      );
      state = state.copyWith(
        location: amapAddress,
        isGettingLocation: false,
      );
      return amapAddress;
    } catch (e) {
      debugPrint('[geolocation_service] Error: $e');
      final error = e is LocationFailure
          ? e
          : const LocationFailure('GPS定位失败，请检查定位权限', retryable: true);

      if (error.retryable &&
          retryCount < AttendanceConstants.maxLocationRetries) {
        state = state.copyWith(
          location:
              '定位失败，正在重试 (${retryCount + 1}/${AttendanceConstants.maxLocationRetries})...',
        );
        await Future.delayed(const Duration(seconds: 2));
        return getCurrentLocation(retryCount: retryCount + 1);
      }

      state = state.copyWith(
        location: error.message,
        isGettingLocation: false,
      );
      return '位置获取失败';
    }
  }

  /// 获取 GPS 位置
  Future<NativeLocationData> _getLocationData() async {
    try {
      return await _tryNativeLocation();
    } on PlatformException catch (e) {
      debugPrint('[geolocation_service] PlatformException: $e');
      switch (e.code) {
        case 'SERVICE_DISABLED':
          throw const LocationFailure('定位服务未开启，请先打开系统定位服务');
        case 'PERMISSION_DENIED':
          throw const LocationFailure('定位权限被拒绝，请允许定位权限后重试');
        case 'LOCATION_TIMEOUT':
          throw const LocationFailure('定位超时，请在开阔区域重试', retryable: true);
        case 'LOCATION_UNAVAILABLE':
          throw const LocationFailure('定位失败，请稍后重试', retryable: true);
        default:
          throw const LocationFailure('定位服务不可用，请稍后重试', retryable: true);
      }
    } on MissingPluginException {
      throw const LocationFailure('当前平台暂不支持定位，请联系管理员');
    } catch (e) {
      debugPrint('[geolocation_service] Error: $e');
      if (e is LocationFailure) rethrow;
      throw const LocationFailure('定位服务不可用，请稍后重试', retryable: true);
    }
  }

  Future<NativeLocationData> _tryNativeLocation() async {
    final serviceEnabled =
        await _locationChannel.invokeMethod<bool>('isLocationServiceEnabled') ??
            false;
    if (!serviceEnabled) {
      throw const LocationFailure('定位服务未开启，请先打开系统定位服务');
    }

    var permission =
        await _locationChannel.invokeMethod<String>('checkPermission') ??
            'denied';
    if (permission != 'granted') {
      permission =
          await _locationChannel.invokeMethod<String>('requestPermission') ??
              'denied';
    }
    if (permission != 'granted') {
      throw const LocationFailure('定位权限被拒绝，请允许定位权限后重试');
    }

    final result = await _locationChannel
        .invokeMapMethod<String, dynamic>('getCurrentPosition')
        .timeout(Duration(milliseconds: AttendanceConstants.locationTimeoutMs));
    if (result == null) {
      throw const LocationFailure('定位失败，请稍后重试', retryable: true);
    }

    final lat = _toDouble(result['lat']);
    final lng = _toDouble(result['lng']);
    if (lat == null || lng == null) {
      throw const LocationFailure('定位数据异常，请稍后重试', retryable: true);
    }

    return NativeLocationData(
      coords: GeoCoords(lat: lat, lng: lng),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 检查是否在围栏范围内
  void checkWithinRange(double fenceLat, double fenceLng, int radius) {
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
