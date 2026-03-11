import 'package:flutter/foundation.dart';
// WebSocket 客户端 - 对应 src/services/websocket/WebSocketClient.ts
// 支持心跳检测、自动重连、Sa-Token 认证

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';

/// WebSocket 连接状态
enum WsStatus { disconnected, connecting, connected, reconnecting }

/// WebSocket 消息类型常量
class WsMessageType {
  WsMessageType._();
  static const String chat = 'chat';
  static const String heartbeat = 'heartbeat';
  static const String ack = 'ack';
  static const String join = 'join';
  static const String leave = 'leave';
  static const String revoke = 'revoke';
}

/// WebSocket 客户端配置
class WebSocketClientConfig {
  final String url;
  final String token;
  final String clientId;
  final Duration heartbeatInterval;
  final int maxReconnectAttempts;
  final void Function(Map<String, dynamic> message)? onMessage;
  final void Function(WsStatus status)? onStatusChange;
  final void Function(Object error)? onError;

  const WebSocketClientConfig({
    required this.url,
    this.token = '',
    this.clientId = 'oa_personnel_client',
    this.heartbeatInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
    this.onMessage,
    this.onStatusChange,
    this.onError,
  });
}

/// WebSocket 客户端
/// 支持心跳检测、自动重连、Sa-Token 认证
class WebSocketClient {
  WebSocketClientConfig _config;
  WebSocketChannel? _channel;
  WsStatus _status = WsStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isManualClose = false;
  StreamSubscription? _subscription;

  WebSocketClient(this._config);

  WsStatus get status => _status;

  void _setStatus(WsStatus status) {
    if (_status != status) {
      _status = status;
      _config.onStatusChange?.call(status);
    }
  }

  /// 标准化 Token，确保有 Bearer 前缀
  String _normalizeToken(String token) {
    if (token.isEmpty) return '';
    return token.startsWith('Bearer ') ? token : 'Bearer $token';
  }

  /// 构建带认证参数的 URL
  Uri _buildAuthUrl() {
    final baseUrl = _config.url;
    final authToken = _normalizeToken(_config.token);
    final params = <String, String>{};

    if (authToken.isNotEmpty) {
      params['Authorization'] = authToken;
    }
    if (_config.clientId.isNotEmpty) {
      params['clientid'] = _config.clientId;
    }

    final uri = Uri.parse(baseUrl);
    return uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_status == WsStatus.connected || _status == WsStatus.connecting) {
      return;
    }

    _isManualClose = false;
    _setStatus(WsStatus.connecting);

    try {
      final uri = _buildAuthUrl();
      _channel = WebSocketChannel.connect(uri);

      // 等待连接就绪（带超时保护，防止无限挂起）
      await _channel!.ready.timeout(const Duration(seconds: 10));

      _setStatus(WsStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      // 监听消息
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _config.onError?.call(error);
        },
        onDone: () {
          _handleClose();
        },
      );
    } catch (e) {
      _setStatus(WsStatus.disconnected);
      _config.onError?.call(e);
      rethrow;
    }
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic data) {
    try {
      final message = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : <String, dynamic>{};

      // 忽略心跳响应
      if (message['type'] == WsMessageType.heartbeat) return;

      _config.onMessage?.call(message);
    } catch (e) { debugPrint('[websocket_client] Error: $e');
      // 忽略格式错误的消息
    }
  }

  /// 处理连接关闭
  void _handleClose() {
    _stopHeartbeat();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (_isManualClose) {
      _setStatus(WsStatus.disconnected);
      return;
    }

    _tryReconnect();
  }

  /// 尝试重连 - 指数退避: 1s, 2s, 4s, 8s, 16s
  void _tryReconnect() {
    if (_reconnectAttempts >= _config.maxReconnectAttempts) {
      _setStatus(WsStatus.disconnected);
      _config.onError?.call(Exception('重连次数已达上限'));
      return;
    }

    _setStatus(WsStatus.reconnecting);
    _reconnectAttempts++;

    final delayMs = (1000 * (1 << (_reconnectAttempts - 1)))
        .clamp(1000, 16000);

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      connect().catchError((_) {
        // 重连失败，handleClose 会继续尝试
      });
    });
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      send({
        'type': WsMessageType.heartbeat,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 发送消息
  bool send(Map<String, dynamic> message) {
    if (_status != WsStatus.connected || _channel == null) return false;

    try {
      _channel!.sink.add(jsonEncode(message));
      return true;
    } catch (e) { debugPrint('[websocket_client] Error: $e');
      return false;
    }
  }

  /// 加入项目房间
  bool joinProject(int projectId) {
    return send({'type': WsMessageType.join, 'projectId': projectId});
  }

  /// 离开项目房间
  bool leaveProject(int projectId) {
    return send({'type': WsMessageType.leave, 'projectId': projectId});
  }

  /// 断开连接
  void disconnect() {
    _isManualClose = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;

    _channel?.sink.close();
    _channel = null;

    _setStatus(WsStatus.disconnected);
  }

  /// 更新认证信息
  void updateAuth(String token, [String? clientId]) {
    _config = WebSocketClientConfig(
      url: _config.url,
      token: token,
      clientId: clientId ?? _config.clientId,
      heartbeatInterval: _config.heartbeatInterval,
      maxReconnectAttempts: _config.maxReconnectAttempts,
      onMessage: _config.onMessage,
      onStatusChange: _config.onStatusChange,
      onError: _config.onError,
    );
  }

  /// 重置重连计数
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }
}

/// 构建 WebSocket URL (http→ws)
String buildWebSocketUrl() {
  final base = ApiConstants.wsBaseUrl;
  return '$base/resource/websocket';
}
