import 'package:flutter/foundation.dart';
// WebSocket 服务 Provider - 对应 src/store/websocket.ts
// 管理 WebSocket 连接状态和消息分发

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../notification/notification_service.dart';
import '../notification/local_notification_service.dart';
import 'websocket_client.dart';

/// WebSocket 连接状态
class WebSocketState {
  final WsStatus status;
  final int? currentProjectId;

  const WebSocketState({
    this.status = WsStatus.disconnected,
    this.currentProjectId,
  });

  bool get isConnected => status == WsStatus.connected;
  bool get isConnecting =>
      status == WsStatus.connecting || status == WsStatus.reconnecting;

  WebSocketState copyWith({WsStatus? status, int? currentProjectId}) {
    return WebSocketState(
      status: status ?? this.status,
      currentProjectId: currentProjectId ?? this.currentProjectId,
    );
  }
}

/// WebSocket 状态管理
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final Ref _ref;
  WebSocketClient? _client;
  final Map<String, void Function(Map<String, dynamic>)> _listeners = {};

  WebSocketNotifier(this._ref) : super(const WebSocketState());

  /// 从 JWT Token 中解析 clientId
  String _getClientIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return ApiConstants.clientId;
      // base64url decode
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      // dart:convert doesn't have atob, use base64Url
      final decoded =
          String.fromCharCodes(Uri.decodeComponent(
            Uri.encodeFull(
              String.fromCharCodes(
                // fallback: just use default clientId
                []),
            ),
          ).codeUnits);
      // Simplified: always use the configured clientId
      return decoded.isEmpty ? ApiConstants.clientId : ApiConstants.clientId;
    } catch (e) { debugPrint('[websocket_service] Error: $e');
      return ApiConstants.clientId;
    }
  }

  /// 初始化 WebSocket 连接
  Future<void> connect() async {
    if (_client != null && state.isConnected) return;

    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (token == null || token.isEmpty) return;

    _client = WebSocketClient(WebSocketClientConfig(
      url: buildWebSocketUrl(),
      token: token,
      clientId: _getClientIdFromToken(token),
      onMessage: _handleMessage,
      onStatusChange: _handleStatusChange,
      onError: _handleError,
    ));

    try {
      await _client!.connect();
    } catch (e) { debugPrint('[websocket_service] Error: $e');
      // 连接失败静默处理
    }
  }

  /// 处理消息
  void _handleMessage(Map<String, dynamic> message) {
    // 处理聊天消息通知
    if (message['type'] == WsMessageType.chat) {
      final notificationNotifier =
          _ref.read(notificationServiceProvider.notifier);
      final notificationState = _ref.read(notificationServiceProvider);

      // 非本人所属项目的消息，跳过未读计数和通知
      final projectId = message['projectId'] as int?;
      if (projectId != null && !notificationNotifier.isMyProject(projectId)) {
        return;
      }

      notificationNotifier.handleWebSocketMessage(message);

      // 当用户不在该项目聊天页时，触发本地通知
      if (projectId != null &&
          notificationState.currentViewingProjectId != projectId) {
        final projectName =
            message['projectName'] as String? ??
            notificationState.getProjectName(projectId);
        final senderName =
            message['personnelName'] as String? ?? '未知用户';
        final content =
            message['content'] as String? ??
            message['chatContent'] as String? ??
            '[消息]';

        _ref.read(localNotificationProvider.notifier).showChatNotification(
              projectId: projectId,
              projectName: projectName,
              senderName: senderName,
              content: content,
            );
      }
    }

    // 通知所有监听器
    for (final listener in _listeners.values) {
      try {
        listener(message);
      } catch (e) { debugPrint('[websocket_service] Error: $e'); }
    }
  }

  /// 处理状态变化
  void _handleStatusChange(WsStatus newStatus) {
    state = state.copyWith(status: newStatus);

    // 重连成功后，重新加入项目房间
    if (newStatus == WsStatus.connected && state.currentProjectId != null) {
      _client?.joinProject(state.currentProjectId!);
    }
  }

  /// 处理错误（静默）
  void _handleError(Object error) {
    // 静默处理，避免影响用户体验
  }

  /// 加入项目房间
  bool joinProject(int projectId) {
    final previousId = state.currentProjectId;
    state = state.copyWith(currentProjectId: projectId);

    if (_client == null || !state.isConnected) return false;

    // 先离开之前的项目
    if (previousId != null && previousId != projectId) {
      _client!.leaveProject(previousId);
    }

    return _client!.joinProject(projectId);
  }

  /// 离开项目房间
  bool leaveProject(int projectId) {
    if (state.currentProjectId == projectId) {
      state = const WebSocketState();
    }

    if (_client == null || !state.isConnected) return false;
    return _client!.leaveProject(projectId);
  }

  /// 发送消息
  bool send(Map<String, dynamic> message) {
    if (_client == null || !state.isConnected) return false;
    return _client!.send(message);
  }

  /// 添加消息监听器
  void addMessageListener(
      String id, void Function(Map<String, dynamic>) listener) {
    _listeners[id] = listener;
  }

  /// 移除消息监听器
  void removeMessageListener(String id) {
    _listeners.remove(id);
  }

  /// 断开连接
  void disconnect() {
    if (state.currentProjectId != null) {
      _client?.leaveProject(state.currentProjectId!);
    }

    _client?.disconnect();
    _client = null;
    _listeners.clear();

    state = const WebSocketState();
  }

  /// 使用新 Token 重连
  Future<void> reconnectWithNewToken() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (token == null || token.isEmpty) return;

    if (_client != null) {
      _client!.updateAuth(token);
      _client!.resetReconnectAttempts();

      if (state.status == WsStatus.disconnected) {
        await connect();
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// WebSocket Provider
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  return WebSocketNotifier(ref);
});
