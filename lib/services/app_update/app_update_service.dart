import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';

/// 版本信息
class VersionInfo {
  final bool hasUpdate;
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String updateContent;
  final bool forceUpdate;
  final String fileSize;

  const VersionInfo({
    this.hasUpdate = false,
    this.versionName = '',
    this.versionCode = 0,
    this.downloadUrl = '',
    this.updateContent = '',
    this.forceUpdate = false,
    this.fileSize = '',
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
        hasUpdate: json['hasUpdate'] as bool? ?? false,
        versionName: json['versionName'] as String? ?? '',
        versionCode: json['versionCode'] as int? ?? 0,
        downloadUrl: json['downloadUrl'] as String? ?? '',
        updateContent: json['updateContent'] as String? ?? '',
        forceUpdate: json['forceUpdate'] as bool? ?? false,
        fileSize: json['fileSize'] as String? ?? '',
      );
}
/// 更新状态
enum UpdateStatus { idle, checking, confirm, downloading, installing }

/// 应用更新状态
class AppUpdateState {
  final UpdateStatus status;
  final double downloadProgress;
  final VersionInfo? versionInfo;

  const AppUpdateState({
    this.status = UpdateStatus.idle,
    this.downloadProgress = 0,
    this.versionInfo,
  });

  bool get hasNewVersion => versionInfo?.hasUpdate == true;

  AppUpdateState copyWith({
    UpdateStatus? status,
    double? downloadProgress,
    VersionInfo? versionInfo,
  }) =>
      AppUpdateState(
        status: status ?? this.status,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        versionInfo: versionInfo ?? this.versionInfo,
      );
}

/// 应用更新管理
class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final Ref _ref;
  CancelToken? _cancelToken;

  static const _remindLaterKey = 'app_update_remind_later_until';
  static const _oneDayMs = 24 * 60 * 60 * 1000;
  static const _installChannel = MethodChannel('oa/install');

  AppUpdateNotifier(this._ref) : super(const AppUpdateState());

  /// 稍后提醒检查
  Future<bool> shouldSkipAutoPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_remindLaterKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final skip = now < until;
    debugPrint('[AppUpdate] shouldSkipAutoPopup: now=$now, until=$until, skip=$skip');
    return skip;
  }

  Future<void> setRemindLaterOneDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _remindLaterKey,
      DateTime.now().millisecondsSinceEpoch + _oneDayMs,
    );
  }

  /// 清除"稍后提醒"标记
  Future<void> clearRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindLaterKey);
  }

  /// 检查更新 - GET /api/app/version/check
  Future<VersionInfo?> checkUpdate() async {
    state = state.copyWith(status: UpdateStatus.checking);
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isAndroid ? 'android' : 'ios';
      debugPrint('[AppUpdate] checking: platform=$platform, currentVersion=$currentVersion');

      final dio = _ref.read(dioProvider);
      final response = await dio.get(
        '/api/app/version/check',
        queryParameters: {
          'platform': platform,
          'currentVersion': currentVersion,
        },
      );

      debugPrint('[AppUpdate] response: ${response.data}');

      final apiRes = ApiResponse.fromJson(
        ensureJsonMap(response.data),
        (json) => VersionInfo.fromJson(json as Map<String, dynamic>),
      );

      debugPrint('[AppUpdate] code=${apiRes.code}, hasData=${apiRes.data != null}');

      if (apiRes.isSuccess && apiRes.data != null) {
        var info = apiRes.data!;
        debugPrint('[AppUpdate] hasUpdate=${info.hasUpdate}, version=${info.versionName}');
        // 补全相对路径
        if (info.downloadUrl.isNotEmpty &&
            !info.downloadUrl.startsWith('http')) {
          info = VersionInfo(
            hasUpdate: info.hasUpdate,
            versionName: info.versionName,
            versionCode: info.versionCode,
            downloadUrl: '${ApiConstants.baseUrl}${info.downloadUrl}',
            updateContent: info.updateContent,
            forceUpdate: info.forceUpdate,
            fileSize: info.fileSize,
          );
        }
        if (mounted) state = state.copyWith(versionInfo: info);
        return info;
      }
      debugPrint('[AppUpdate] API returned no data or not success');
      return null;
    } catch (e, stack) {
      debugPrint('[AppUpdate] checkUpdate error: $e');
      debugPrint('[AppUpdate] stack: $stack');
      return null;
    } finally {
      if (mounted) state = state.copyWith(status: UpdateStatus.idle);
    }
  }

  /// 下载并安装 APK (仅 Android)
  Future<void> downloadAndInstall(String url) async {
    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0,
    );
    _cancelToken = CancelToken();

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/oa_update.apk';

      final dio = Dio(); // 下载用独立 Dio，不走拦截器
      await dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            state = state.copyWith(
              downloadProgress: received / total,
            );
          }
        },
      );

      if (!mounted) return;
      state = state.copyWith(status: UpdateStatus.installing);

      if (Platform.isAndroid) {
        await _installChannel.invokeMethod('installApk', {'filePath': savePath});
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('[AppUpdate] download cancelled');
      } else {
        debugPrint('[AppUpdate] download error: $e');
      }
    } catch (e) {
      debugPrint('[AppUpdate] install error: $e');
    } finally {
      if (mounted) state = state.copyWith(status: UpdateStatus.idle);
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
  }

  void reset() {
    state = const AppUpdateState();
  }
}

/// Provider
final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier(ref);
});

/// 版本号比较
int compareVersion(String v1, String v2) {
  final arr1 = v1.split('.').map(int.parse).toList();
  final arr2 = v2.split('.').map(int.parse).toList();
  final len = arr1.length > arr2.length ? arr1.length : arr2.length;
  for (var i = 0; i < len; i++) {
    final n1 = i < arr1.length ? arr1[i] : 0;
    final n2 = i < arr2.length ? arr2[i] : 0;
    if (n1 > n2) return 1;
    if (n1 < n2) return -1;
  }
  return 0;
}
