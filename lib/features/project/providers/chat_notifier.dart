// 聊天状态管理 - 业务逻辑从 ProjectProgressPage 抽离
// Phase 2: WebSocket 集成

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification/notification_service.dart';
import '../../../services/notification/local_notification_service.dart';
import '../../../services/websocket/websocket_client.dart';
import '../../../services/websocket/websocket_service.dart';
import '../data/api/project_api.dart';
import '../data/models/project_models.dart';

/// 聊天状态
class ChatState {
  final List<ChatRecordVo> messages;
  final List<ProjectStaffVo> members;
  final Map<int, String> memberNameMap;
  final bool isLoading;
  final bool isSending;
  final ChatRecordVo? replyTarget;

  const ChatState({
    this.messages = const [],
    this.members = const [],
    this.memberNameMap = const {},
    this.isLoading = true,
    this.isSending = false,
    this.replyTarget,
  });

  ChatState copyWith({
    List<ChatRecordVo>? messages,
    List<ProjectStaffVo>? members,
    Map<int, String>? memberNameMap,
    bool? isLoading,
    bool? isSending,
    ChatRecordVo? replyTarget,
    bool clearReplyTarget = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      members: members ?? this.members,
      memberNameMap: memberNameMap ?? this.memberNameMap,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      replyTarget: clearReplyTarget ? null : (replyTarget ?? this.replyTarget),
    );
  }
}

/// 聊天状态 Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final int projectId;
  final ProjectApi _api;
  final WebSocketNotifier _wsNotifier;
  final NotificationNotifier _notificationNotifier;
  final LocalNotificationNotifier _localNotificationNotifier;
  final String _listenerId;
  Timer? _refreshTimer;

  ChatNotifier({
    required this.projectId,
    required ProjectApi api,
    required WebSocketNotifier wsNotifier,
    required NotificationNotifier notificationNotifier,
    required LocalNotificationNotifier localNotificationNotifier,
  })  : _api = api,
        _wsNotifier = wsNotifier,
        _notificationNotifier = notificationNotifier,
        _localNotificationNotifier = localNotificationNotifier,
        _listenerId = 'chat_$projectId',
        super(const ChatState()) {
    // 延迟到 provider 构造完成后再执行初始化，
    // 避免 Riverpod 报错 "Providers are not allowed to modify other providers during their initialization"
    Future.microtask(_init);
  }

  Future<void> _init() async {
    debugPrint('[chat_notifier] _init start for projectId=$projectId');

    // 标记当前查看的项目（清除未读）
    _notificationNotifier.setCurrentViewingProject(projectId);

    // 清除通知栏中该项目的本地通知
    _localNotificationNotifier.cancelProjectNotification(projectId);

    // 注册 WebSocket 消息监听
    _wsNotifier.addMessageListener(_listenerId, _onWsMessage);

    // 先通过 HTTP 加载历史数据（保证页面能显示）
    await loadInitialData();

    debugPrint('[chat_notifier] _init loadInitialData done, isLoading=${state.isLoading}');

    // 启动后备轮询
    startAutoRefresh();

    // WebSocket 连接放后台，不阻塞 UI
    _connectWebSocket();

    debugPrint('[chat_notifier] _init complete for projectId=$projectId');
  }

  /// 后台尝试 WebSocket 连接，失败不影响页面
  Future<void> _connectWebSocket() async {
    try {
      await _wsNotifier.connect();
      _wsNotifier.joinProject(projectId);
    } catch (e) {
      debugPrint('[chat_notifier] WebSocket connect failed (non-blocking): $e');
    }
  }

  /// 加载初始数据
  Future<void> loadInitialData() async {
    debugPrint('[chat_notifier] loadInitialData start, mounted=$mounted');
    try {
      await Future.wait([
        fetchMessages(),
        fetchMembers(),
      ]);
      debugPrint('[chat_notifier] loadInitialData HTTP calls done');
    } catch (e) {
      debugPrint('[chat_notifier] loadInitialData error: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
        debugPrint('[chat_notifier] loadInitialData set isLoading=false');
      } else {
        debugPrint('[chat_notifier] loadInitialData: NOT mounted, cannot set isLoading=false');
      }
    }
  }

  /// 安全解析 int（兼容后端传 String 或 int）
  static int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 处理 WebSocket 消息
  void _onWsMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    final type = message['type'] as String?;

    if (type == WsMessageType.chat) {
      final msgProjectId = _safeInt(message['projectId']);
      if (msgProjectId != projectId) return;

      // 后端发送的字段名是 messageId (String)，而非 id
      final msgId = _safeInt(message['messageId'] ?? message['id']);

      // 去重: 如果已有相同 id 的消息则跳过
      final existing = state.messages;
      if (msgId != null && existing.any((m) => m.id == msgId)) {
        return;
      }

      // 解析文件信息（后端嵌套在 fileInfo 对象中）
      final fileInfo = message['fileInfo'] as Map<String, dynamic>?;

      final newMsg = ChatRecordVo(
        id: msgId,
        projectId: msgProjectId,
        personnelId: _safeInt(message['personnelId']),
        personnelName: message['personnelName'] as String?,
        chatContent: message['chatContent'] as String? ??
            message['content'] as String?,
        imageUrl: message['imageUrl'] as String? ??
            (fileInfo != null ? fileInfo['url'] as String? : null),
        fileUrl: message['fileUrl'] as String? ??
            (fileInfo != null ? fileInfo['url'] as String? : null),
        fileType: _safeInt(message['fileType']),
        fileName: message['fileName'] as String? ??
            (fileInfo != null ? fileInfo['name'] as String? : null),
        fileSize: _safeInt(message['fileSize'] ??
            (fileInfo != null ? fileInfo['size'] : null)),
        atPersonnelIds: message['atPersonnelIds'] as String?,
        replyId: _safeInt(message['replyId']),
        replyContent: message['replyContent'] as String?,
        replyUserName: message['replyUserName'] as String?,
        createTime: message['createTime'] as String?,
        delFlag: 0,
      );

      state = state.copyWith(
        messages: [...existing, newMsg],
      );
    } else if (type == WsMessageType.revoke) {
      final msgId = _safeInt(message['messageId'] ?? message['id']);
      if (msgId == null) return;

      // 标记消息为已撤回 (delFlag=2)
      final updated = state.messages.map((m) {
        if (m.id == msgId) return m.copyWith(delFlag: 2);
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    }
  }

  /// 获取聊天记录
  Future<void> fetchMessages() async {
    try {
      debugPrint('[chat_notifier] fetchMessages start for projectId=$projectId');
      final res = await _api.getChatRecordList(projectId: projectId);
      debugPrint('[chat_notifier] fetchMessages response: isSuccess=${res.isSuccess}, rows=${res.rows?.length}');
      if (res.isSuccess && mounted) {
        final records =
            (res.rows ?? []).where((r) => r.delFlag != 2).toList();
        state = state.copyWith(messages: records);
      }
    } catch (e) {
      debugPrint('[chat_notifier] fetchMessages error: $e');
    }
  }

  /// 获取项目成员
  Future<void> fetchMembers() async {
    try {
      debugPrint('[chat_notifier] fetchMembers start for projectId=$projectId');
      final res = await _api.getProjectStaffList(projectId: projectId);
      debugPrint('[chat_notifier] fetchMembers response: isSuccess=${res.isSuccess}, rows=${res.rows?.length}');
      if (res.isSuccess && mounted) {
        final members =
            (res.rows ?? []).where((m) => m.delFlag != 2).toList();
        final nameMap = <int, String>{};
        for (final m in members) {
          if (m.personnelId != null && m.name != null) {
            nameMap[m.personnelId!] = m.name!;
          }
        }
        state = state.copyWith(members: members, memberNameMap: nameMap);
      }
    } catch (e) {
      debugPrint('[chat_notifier] fetchMembers error: $e');
    }
  }

  /// 解析发送者姓名
  String resolveSenderName(
      int? personnelId, int currentUserId, String currentUserName,
      {String? personnelName}) {
    if (personnelId == currentUserId) return currentUserName;
    // 优先使用后端返回的名称
    if (personnelName != null && personnelName.isNotEmpty) {
      return personnelName;
    }
    if (personnelId != null && state.memberNameMap.containsKey(personnelId)) {
      return state.memberNameMap[personnelId]!;
    }
    return '用户$personnelId';
  }

  /// 发送文本消息
  /// API 成功后依赖 WebSocket 推送显示消息，3秒内未收到则 fallback 刷新
  Future<bool> sendMessage({
    required int personnelId,
    required String chatContent,
    String? atPersonnelIds,
  }) async {
    final text = chatContent.trim();
    if (text.isEmpty) return false;

    // 先捕获回复目标，再清空状态
    final reply = state.replyTarget;
    state = state.copyWith(isSending: true, clearReplyTarget: true);

    final msgCountBefore = state.messages.length;

    try {
      final res = await _api.sendChatMessage(
        projectId: projectId,
        personnelId: personnelId,
        chatContent: text,
        atPersonnelIds: atPersonnelIds,
        replyId: reply?.id,
        replyContent: reply?.chatContent,
        replyUserName: reply?.personnelName,
      );
      if (res.isSuccess) {
        // 等待 WebSocket 推送消息到达（最多 3 秒）
        await _waitForNewMessage(msgCountBefore);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[chat_notifier] sendMessage error: $e');
      return false;
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
    }
  }

  /// 等待新消息到达，超时则 fallback fetchMessages
  Future<void> _waitForNewMessage(int countBefore, {int timeoutMs = 3000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      if (!mounted) return;
      if (state.messages.length > countBefore) return; // WebSocket 已推送
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // 超时：WebSocket 未推送，fallback 刷新
    debugPrint('[chat_notifier] WS timeout, fallback fetchMessages');
    await fetchMessages();
  }

  /// 上传本地图片并发送图片消息
  Future<bool> uploadAndSendImage({
    required int personnelId,
    required String filePath,
    String? fileName,
  }) async {
    try {
      state = state.copyWith(isSending: true);
      final uploadRes = await _api.uploadFile(filePath, fileName: fileName);
      if (!uploadRes.isSuccess || uploadRes.data == null) {
        debugPrint('[chat_notifier] uploadAndSendImage upload failed: ${uploadRes.msg}');
        return false;
      }
      final url = uploadRes.data!['url'] as String?;
      if (url == null || url.isEmpty) return false;

      return await sendImageMessage(
        personnelId: personnelId,
        imageUrl: url,
      );
    } catch (e) {
      debugPrint('[chat_notifier] uploadAndSendImage error: $e');
      return false;
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
    }
  }

  /// 上传本地文件并发送文件消息
  Future<bool> uploadAndSendFile({
    required int personnelId,
    required String filePath,
    required String fileName,
    required int fileSize,
    int fileType = 2,
  }) async {
    try {
      state = state.copyWith(isSending: true);
      final uploadRes = await _api.uploadFile(filePath, fileName: fileName);
      if (!uploadRes.isSuccess || uploadRes.data == null) {
        debugPrint('[chat_notifier] uploadAndSendFile upload failed: ${uploadRes.msg}');
        return false;
      }
      final url = uploadRes.data!['url'] as String?;
      if (url == null || url.isEmpty) return false;

      return await sendFileMessage(
        personnelId: personnelId,
        fileUrl: url,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
      );
    } catch (e) {
      debugPrint('[chat_notifier] uploadAndSendFile error: $e');
      return false;
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
    }
  }

  /// 发送图片消息
  Future<bool> sendImageMessage({
    required int personnelId,
    required String imageUrl,
  }) async {
    try {
      final reply = state.replyTarget;
      final msgCountBefore = state.messages.length;
      final res = await _api.sendChatMessageWithAttachment(
        projectId: projectId,
        personnelId: personnelId,
        imageUrl: imageUrl,
        fileType: 1,
        replyId: reply?.id,
        replyContent: reply?.chatContent,
        replyUserName: reply?.personnelName,
      );
      if (res.isSuccess) {
        state = state.copyWith(clearReplyTarget: true);
        await _waitForNewMessage(msgCountBefore);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[chat_notifier] sendImageMessage error: $e');
      return false;
    }
  }

  /// 发送文件消息
  Future<bool> sendFileMessage({
    required int personnelId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    int fileType = 2,
  }) async {
    try {
      final reply = state.replyTarget;
      final msgCountBefore = state.messages.length;
      final res = await _api.sendChatMessageWithAttachment(
        projectId: projectId,
        personnelId: personnelId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        replyId: reply?.id,
        replyContent: reply?.chatContent,
        replyUserName: reply?.personnelName,
      );
      if (res.isSuccess) {
        state = state.copyWith(clearReplyTarget: true);
        await _waitForNewMessage(msgCountBefore);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[chat_notifier] sendFileMessage error: $e');
      return false;
    }
  }

  /// 撤回消息
  Future<bool> revokeMessage(int messageId, int personnelId) async {
    try {
      final res = await _api.revokeChatMessage(messageId, personnelId);
      if (res.isSuccess) {
        // 本地立即标记为已撤回（后端也会通过 WebSocket 广播）
        final updated = state.messages.map((m) {
          if (m.id == messageId) return m.copyWith(delFlag: 2);
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
        return true;
      }
      debugPrint('[chat_notifier] revokeMessage failed: '
          'code=${res.code}, msg=${res.msg}');
      return false;
    } catch (e) {
      debugPrint('[chat_notifier] revokeMessage error: $e');
      return false;
    }
  }

  /// 删除消息（本地移除）
  void removeLocalMessage(int messageId) {
    final filtered = state.messages.where((m) => m.id != messageId).toList();
    state = state.copyWith(messages: filtered);
  }

  /// 设置回复目标
  void setReplyTarget(ChatRecordVo? target) {
    if (target == null) {
      state = state.copyWith(clearReplyTarget: true);
    } else {
      state = state.copyWith(replyTarget: target);
    }
  }

  /// 取消回复
  void cancelReply() {
    state = state.copyWith(clearReplyTarget: true);
  }

  /// 开始回复某条消息
  void startReply(ChatRecordVo message) {
    state = state.copyWith(replyTarget: message);
  }

  /// 自己的消息始终可撤回（无时间限制）
  bool canRevokeMessage(ChatRecordVo message) {
    return true;
  }

  /// 从文本中提取被 @提及的人员 ID 列表
  /// 返回逗号分隔的 ID 字符串，无匹配时返回 null
  String? extractAtPersonnelIds(String text) {
    if (!text.contains('@')) return null;

    // 反转 memberNameMap: name → id，按姓名长度降序排列避免短名截断长名
    final nameToId = <String, int>{};
    for (final entry in state.memberNameMap.entries) {
      nameToId[entry.value] = entry.key;
    }
    final sortedNames = nameToId.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final matchedIds = <int>{};
    for (final name in sortedNames) {
      if (text.contains('@$name')) {
        matchedIds.add(nameToId[name]!);
      }
    }

    if (matchedIds.isEmpty) return null;
    return matchedIds.join(',');
  }

  /// 启动自动刷新（降频为30秒，作为 WebSocket 断线时的后备）
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchMessages(),
    );
  }

  /// 停止自动刷新
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 标记当前正在查看该项目（前台时调用，抑制本地通知）
  void setCurrentViewingProject(int projectId) {
    _notificationNotifier.setCurrentViewingProject(projectId);
  }

  /// 清除"正在查看"标记（后台时调用，允许本地通知）
  void clearCurrentViewingProject() {
    _notificationNotifier.setCurrentViewingProject(null);
  }

  @override
  void dispose() {
    debugPrint('[chat_notifier] dispose for projectId=$projectId');
    _refreshTimer?.cancel();
    // 移除 WebSocket 监听并离开项目房间
    _wsNotifier.removeMessageListener(_listenerId);
    _wsNotifier.leaveProject(projectId);
    _notificationNotifier.setCurrentViewingProject(null);
    super.dispose();
  }
}
