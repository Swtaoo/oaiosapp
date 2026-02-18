import 'package:flutter/foundation.dart';
// 应用更新服务 - 对应 src/store/appUpdate.ts + src/utils/appUpdate.ts
// 版本检查、下载、安装

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';

/// 版本信息 - 对应 src/api/version.ts VersionInfo
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
enum UpdateStatus { checking, confirm, downloading, installing }

/// 应用更新状态
class AppUpdateState {
  final bool updateModalVisible;
  final UpdateStatus updateStatus;
  final double downloadProgress;
  final VersionInfo? versionInfo;
  final bool isChecking;
  final bool hasNewVersion;

  const AppUpdateState({
    this.updateModalVisible = false,
    this.updateStatus = UpdateStatus.checking,
    this.downloadProgress = 0,
    this.versionInfo,
    this.isChecking = false,
    this.hasNewVersion = false,
  });

  AppUpdateState copyWith({
    bool? updateModalVisible,
    UpdateStatus? updateStatus,
    double? downloadProgress,
    VersionInfo? versionInfo,
    bool? isChecking,
    bool? hasNewVersion,
  }) {
    return AppUpdateState(
      updateModalVisible: updateModalVisible ?? this.updateModalVisible,
      updateStatus: updateStatus ?? this.updateStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      versionInfo: versionInfo ?? this.versionInfo,
      isChecking: isChecking ?? this.isChecking,
      hasNewVersion: hasNewVersion ?? this.hasNewVersion,
    );
  }
}

/// 应用更新管理
class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final Ref _ref;

  static const _remindLaterKey = 'app_update_remind_later_until';
  static const _oneDayMs = 24 * 60 * 60 * 1000;

  AppUpdateNotifier(this._ref) : super(const AppUpdateState());

  /// 检查是否应跳过自动弹窗（稍后提醒）
  Future<bool> shouldSkipAutoPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_remindLaterKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  /// 设置稍后提醒（一天后）
  Future<void> setRemindLaterOneDay() async {
    final prefs = await SharedPreferences.getInstance();
    final remindAt = DateTime.now().millisecondsSinceEpoch + _oneDayMs;
    await prefs.setInt(_remindLaterKey, remindAt);
  }

  /// 清除稍后提醒
  Future<void> clearRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindLaterKey);
  }

  /// 检查更新
  /// GET /api/app/version/check?platform=android&currentVersion=1.0.0
  Future<VersionInfo?> checkUpdate() async {
    state = state.copyWith(isChecking: true);
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      // TODO: 获取实际版本号 (package_info_plus)
      const currentVersion = '1.0.0';

      final dio = _ref.read(dioProvider);
      final response = await dio.get(
        '/api/app/version/check',
        queryParameters: {
          'platform': platform,
          'currentVersion': currentVersion,
        },
      );

      final apiRes = ApiResponse.fromJson(
        ensureJsonMap(response.data),
        (json) => VersionInfo.fromJson(json as Map<String, dynamic>),
      );

      if (apiRes.isSuccess && apiRes.data != null) {
        final info = apiRes.data!;

        // 补全相对路径的 downloadUrl
        if (info.downloadUrl.isNotEmpty &&
            !info.downloadUrl.startsWith('http')) {
          final fullUrl = '${ApiConstants.baseUrl}${info.downloadUrl}';
          final updatedInfo = VersionInfo(
            hasUpdate: info.hasUpdate,
            versionName: info.versionName,
            versionCode: info.versionCode,
            downloadUrl: fullUrl,
            updateContent: info.updateContent,
            forceUpdate: info.forceUpdate,
            fileSize: info.fileSize,
          );
          state = state.copyWith(
            versionInfo: updatedInfo,
            hasNewVersion: updatedInfo.hasUpdate,
          );
          return updatedInfo;
        }

        state = state.copyWith(
          versionInfo: info,
          hasNewVersion: info.hasUpdate,
        );
        return info;
      }
      return null;
    } catch (e) { debugPrint('[app_update_service] Error: $e');
      return null;
    } finally {
      if (mounted) state = state.copyWith(isChecking: false);
    }
  }

  /// 显示更新弹窗
  void showUpdateModal() {
    state = state.copyWith(
      updateModalVisible: true,
      updateStatus: UpdateStatus.confirm,
    );
  }

  /// 隐藏更新弹窗
  void hideUpdateModal() {
    state = state.copyWith(updateModalVisible: false);
  }

  /// 清除新版本标记
  void clearNewVersion() {
    state = state.copyWith(
      versionInfo: null,
      hasNewVersion: false,
    );
  }
}

/// 应用更新 Provider
final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier(ref);
});

/// 版本号比较工具
int compareVersion(String v1, String v2) {
  final arr1 = v1.split('.').map(int.parse).toList();
  final arr2 = v2.split('.').map(int.parse).toList();
  final len = arr1.length > arr2.length ? arr1.length : arr2.length;

  for (var i = 0; i < len; i++) {
    final num1 = i < arr1.length ? arr1[i] : 0;
    final num2 = i < arr2.length ? arr2[i] : 0;
    if (num1 > num2) return 1;
    if (num1 < num2) return -1;
  }
  return 0;
}
