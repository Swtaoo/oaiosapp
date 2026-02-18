// 聊天相关 Riverpod Providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification/notification_service.dart';
import '../../../services/websocket/websocket_service.dart';
import 'chat_notifier.dart';
import 'project_providers.dart';

/// 按 projectId 隔离的聊天状态 Provider
/// autoDispose: 离开聊天页面时自动清理（含 WS 监听器 + 项目房间）
///
/// 重要: wsNotifier 和 notificationNotifier 使用 ref.read 而非 ref.watch，
/// 因为它们是长生命周期的全局单例，其 state 变化不应触发 ChatNotifier 重建。
/// 使用 ref.watch 会导致无限循环：
///   ChatNotifier._init() -> setCurrentViewingProject() -> state 变化 -> provider 重建 -> 再次 _init()
final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, int>((ref, projectId) {
  final api = ref.watch(projectApiProvider);
  final wsNotifier = ref.read(webSocketProvider.notifier);
  final notificationNotifier = ref.read(notificationServiceProvider.notifier);
  return ChatNotifier(
    projectId: projectId,
    api: api,
    wsNotifier: wsNotifier,
    notificationNotifier: notificationNotifier,
  );
});
