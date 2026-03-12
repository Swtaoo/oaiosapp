import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jpush_flutter/jpush_flutter.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../notification/local_notification_service.dart';
import '../notification/notification_service.dart';

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
  final JPush _jpush = JPush();

  PushNotifier(this._ref) : super(const PushState());

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// 初始化推送服务
  Future<void> initPush() async {
    if (state.isInitialized) return;

    try {
      _jpush.setup(
        appKey: '081191f8285f4ca2ecc1f9e2',
        channel: 'developer-default',
        production: false,
        debug: !kReleaseMode,
      );

      // 注册事件处理
      _jpush.addEventHandler(
        onReceiveNotification: (Map<String, dynamic> message) async {
          debugPrint('[push_service] onReceiveNotification: $message');
          _dispatchEvent(message, 'receive');
        },
        onOpenNotification: (Map<String, dynamic> message) async {
          debugPrint('[push_service] onOpenNotification: $message');
          _dispatchEvent(message, 'click');
          _handleNotificationClick(message);
        },
        onConnected: (Map<String, dynamic> message) async {
          debugPrint('[push_service] onConnected: $message');
          // 连接成功后获取 registrationId
          _fetchRegistrationId();
        },
      );

      // 获取 registrationId
      _fetchRegistrationId();

      // iOS 请求推送权限
      if (Platform.isIOS) {
        _jpush.applyPushAuthority(
          const NotificationSettingsIOS(
            sound: true,
            alert: true,
            badge: true,
          ),
        );
      }

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      debugPrint('[push_service] initPush error: $e');
    }
  }

  /// 获取 JPush registrationId 并绑定
  Future<void> _fetchRegistrationId() async {
    try {
      final rid = await _jpush.getRegistrationID();
      if (rid.isNotEmpty) {
        debugPrint('[push_service] registrationId: $rid');
        state = state.copyWith(lastClientId: rid);
        bindClientId();
      }
    } catch (e) {
      debugPrint('[push_service] getRegistrationID error: $e');
    }
  }

  /// 分发推送事件给监听器
  void _dispatchEvent(Map<String, dynamic> message, String type) {
    final title = message['title'] as String? ?? '';
    final content = message['alert'] as String? ??
        message['content'] as String? ??
        '';
    final extras = message['extras'] as Map<String, dynamic>? ?? {};

    final event = PushEvent(
      title: title,
      content: content,
      payload: extras,
      type: type,
    );

    for (final listener in _listeners.values) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('[push_service] listener error: $e');
      }
    }
  }

  /// 处理通知点击 - 导航到对应聊天页
  void _handleNotificationClick(Map<String, dynamic> message) {
    final extras = message['extras'] as Map<String, dynamic>? ?? {};
    final projectIdStr = extras['projectId']?.toString();
    final projectName = extras['projectName'] as String? ?? '';

    if (projectIdStr == null) return;
    final projectId = int.tryParse(projectIdStr);
    if (projectId == null) return;

    // 非本人所属项目，不导航
    final notifier = _ref.read(notificationServiceProvider.notifier);
    if (!notifier.isMyProject(projectId)) {
      debugPrint('[push_service] 忽略非成员项目推送点击: projectId=$projectId');
      return;
    }

    final context = LocalNotificationNotifier.navigatorKey?.currentContext;
    if (context != null) {
      GoRouter.of(context).push(
        '/project/progress?id=$projectId&name=${Uri.encodeComponent(projectName)}',
      );
    }
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
    } catch (e) {
      debugPrint('[push_service] bindClientId error: $e');
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
