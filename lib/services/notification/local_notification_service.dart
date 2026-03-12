import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 本地通知状态
class LocalNotificationState {
  final bool isInitialized;

  const LocalNotificationState({this.isInitialized = false});

  LocalNotificationState copyWith({bool? isInitialized}) {
    return LocalNotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// 本地通知服务 - 封装 flutter_local_notifications
class LocalNotificationNotifier extends StateNotifier<LocalNotificationState> {
  LocalNotificationNotifier() : super(const LocalNotificationState());

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 全局 NavigatorKey，由 App 启动时设置
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 项目成员身份检查回调，由 App 启动时设置
  static bool Function(int projectId)? isMyProjectChecker;

  static const _channelId = 'oa_chat_messages';
  static const _channelName = '项目消息';
  static const _channelDescription = '项目聊天消息通知';

  /// 初始化本地通知
  Future<void> init() async {
    if (state.isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Android: 创建高优先级通知渠道
      if (Platform.isAndroid) {
        final androidPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
          // Android 13+ 请求通知权限
          await androidPlugin.requestNotificationsPermission();
        }
      }

      state = state.copyWith(isInitialized: true);
    } on MissingPluginException catch (e) {
      debugPrint('[local_notification_service] init skipped: $e');
    } catch (e) {
      // flutter test / 未注册插件 / 非目标平台下可能会初始化失败，不影响主流程
      debugPrint('[local_notification_service] init skipped: $e');
    }
  }

  /// 展示聊天通知
  /// 同一项目的消息会覆盖旧通知（使用 projectId 作为通知 ID）
  Future<void> showChatNotification({
    required int projectId,
    required String projectName,
    required String senderName,
    required String content,
  }) async {
    if (!state.isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: '$senderName: $content',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // payload 格式: projectId|projectName
    final payload = '$projectId|$projectName';

    await _plugin.show(
      projectId, // 同项目覆盖
      projectName,
      '$senderName: $content',
      details,
      payload: payload,
    );
  }

  /// 通知点击回调
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');
    if (parts.length < 2) return;

    final projectId = int.tryParse(parts[0]);
    final projectName = parts.sublist(1).join('|'); // 项目名可能含 |

    if (projectId == null) return;

    // 非本人所属项目，不导航
    if (isMyProjectChecker != null && !isMyProjectChecker!(projectId)) {
      debugPrint('[local_notification] 忽略非成员项目通知点击: projectId=$projectId');
      return;
    }

    // 使用全局 navigatorKey 进行导航
    final context = navigatorKey?.currentContext;
    if (context != null) {
      GoRouter.of(context).push(
        '/project/progress?id=$projectId&name=${Uri.encodeComponent(projectName)}',
      );
    }
  }

  /// 取消指定项目的通知
  Future<void> cancelProjectNotification(int projectId) async {
    await _plugin.cancel(projectId);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

/// 本地通知服务 Provider
final localNotificationProvider =
    StateNotifierProvider<LocalNotificationNotifier, LocalNotificationState>(
        (ref) {
  return LocalNotificationNotifier();
});
