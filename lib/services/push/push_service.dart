import 'package:flutter/foundation.dart';
// 推送服务 - 对应 src/store/push.ts
// 推送注册、绑定、监听
// 注意: 实际使用需安装 jpush_flutter 或其他推送 SDK

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';

/// 推送事件
class PushEvent {
  final String title;
  final String content;
  final Map<String, dynamic> payload;
  final String type; // 'click' | 'receive'

  const PushEvent({
    required this.title,
    required this.content,
    required this.payload,
    required this.type,
  });
}

/// 推送状态
class PushState {
  final String lastClientId;
  final bool isBinding;
  final bool isInBackground;
  final bool isInitialized;

  const PushState({
    this.lastClientId = '',
    this.isBinding = false,
    this.isInBackground = false,
    this.isInitialized = false,
  });

  PushState copyWith({
    String? lastClientId,
    bool? isBinding,
    bool? isInBackground,
    bool? isInitialized,
  }) {
    return PushState(
      lastClientId: lastClientId ?? this.lastClientId,
      isBinding: isBinding ?? this.isBinding,
      isInBackground: isInBackground ?? this.isInBackground,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// 推送服务管理
class PushNotifier extends StateNotifier<PushState> {
  final Ref _ref;
  final Map<String, void Function(PushEvent)> _listeners = {};

  PushNotifier(this._ref) : super(const PushState());

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// 初始化推送服务
  /// 注意: 实际实现需要集成 jpush_flutter
  Future<void> initPush() async {
    if (state.isInitialized) return;

    try {
      // TODO: 集成 jpush_flutter 后在此初始化
      // final jpush = JPush();
      // jpush.setup(appKey: 'YOUR_JPUSH_APP_KEY', channel: 'developer-default');
      // jpush.addEventHandler(
      //   onReceiveNotification: (msg) => _dispatch(msg, 'receive'),
      //   onOpenNotification: (msg) => _dispatch(msg, 'click'),
      //   onReceiveRegistrationId: (rid) => _bindClientId(rid),
      // );

      state = state.copyWith(isInitialized: true);
    } catch (e) { debugPrint('[push_service] Error: $e'); }
  }

  /// 绑定推送客户端 ID 到后端
  Future<void> bindClientId({bool force = false}) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (token == null || token.isEmpty || state.isBinding) return;

    final platform = _getPlatform();
    if (platform == 'unknown') return;

    final clientId = state.lastClientId;
    if (clientId.isEmpty) return;

    state = state.copyWith(isBinding: true);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/oa/push/bind', data: {
        'clientId': clientId,
        'platform': platform,
      });
    } catch (e) { debugPrint('[push_service] Error: $e');
    } finally {
      if (mounted) state = state.copyWith(isBinding: false);
    }
  }

  /// 添加推送监听器
  void addPushListener(String key, void Function(PushEvent) handler) {
    _listeners[key] = handler;
  }

  /// 移除推送监听器
  void removePushListener(String key) {
    _listeners.remove(key);
  }

  /// 应用进入后台
  void onEnterBackground() {
    state = state.copyWith(isInBackground: true);
  }

  /// 应用进入前台
  void onEnterForeground() {
    state = state.copyWith(isInBackground: false);
    bindClientId();
  }

  /// 销毁推送服务
  void destroy() {
    _listeners.clear();
    state = const PushState();
  }
}

/// 推送服务 Provider
final pushServiceProvider =
    StateNotifierProvider<PushNotifier, PushState>((ref) {
  return PushNotifier(ref);
});
