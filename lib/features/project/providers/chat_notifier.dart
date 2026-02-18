// 聊天状态管理 - 业务逻辑从 ProjectProgressPage 抽离
// Phase 2: WebSocket 集成 + 乐观发送

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification/notification_service.dart';
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
  final Set<String> sendingIds;
  final Set<String> failedIds;

  const ChatState({
    this.messages = const [],
    this.members = const [],
    this.memberNameMap = const {},
    this.isLoading = true,
    this.isSending = false,
    this.replyTarget,
    this.sendingIds = const {},
    this.failedIds = const {},
  });

  ChatState copyWith({
    List<ChatRecordVo>? messages,
    List<ProjectStaffVo>? members,
    Map<int, String>? memberNameMap,
    bool? isLoading,
    bool? isSending,
    ChatRecordVo? replyTarget,
    bool clearReplyTarget = false,
    Set<String>? sendingIds,
    Set<String>? failedIds,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      members: members ?? this.members,
      memberNameMap: memberNameMap ?? this.memberNameMap,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      replyTarget: clearReplyTarget ? null : (replyTarget ?? this.replyTarget),
      sendingIds: sendingIds ?? this.sendingIds,
      failedIds: failedIds ?? this.failedIds,
    );
  }
}

/// 聊天状态 Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final int projectId;
  final ProjectApi _api;
  final WebSocketNotifier _wsNotifier;
  final NotificationNotifier _notificationNotifier;
  final String _listenerId;
  Timer? _refreshTimer;
  int _localTempCounter = 0;

  ChatNotifier({
    required this.projectId,
    required ProjectApi api,
    required WebSocketNotifier wsNotifier,
    required NotificationNotifier notificationNotifier,
  })  : _api = api,
        _wsNotifier = wsNotifier,
        _notificationNotifier = notificationNotifier,
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

  /// 处理 WebSocket 消息
  void _onWsMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    final type = message['type'] as String?;

    if (type == WsMessageType.chat) {
      final msgProjectId = message['projectId'] as int?;
      if (msgProjectId != projectId) return;

      // 构造 ChatRecordVo 并去重追加
      final newMsg = ChatRecordVo(
        id: message['id'] as int?,
        projectId: msgProjectId,
        personnelId: message['personnelId'] as int?,
        chatContent: message['chatContent'] as String? ??
            message['content'] as String?,
        imageUrl: message['imageUrl'] as String?,
        fileUrl: message['fileUrl'] as String?,
        fileType: message['fileType'] as int?,
        fileName: message['fileName'] as String?,
        fileSize: message['fileSize'] as int?,
        replyId: message['replyId'] as int?,
        replyContent: message['replyContent'] as String?,
        replyUserName: message['replyUserName'] as String?,
        createTime: message['createTime'] as String?,
        delFlag: 0,
      );

      // 去重: 如果已有相同 id 的消息则跳过
      final existing = state.messages;
      if (newMsg.id != null &&
          existing.any((m) => m.id == newMsg.id)) {
        return;
      }

      state = state.copyWith(
        messages: [...existing, newMsg],
      );
    } else if (type == WsMessageType.revoke) {
      final msgId = message['messageId'] as int? ?? message['id'] as int?;
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

        // 保留正在发送的本地消息（尚未出现在服务器结果中）
        final serverIds = records
            .where((r) => r.id != null)
            .map((r) => r.id!)
            .toSet();
        final pendingLocal = state.messages
            .where((m) =>
                m.localTempId != null &&
                (m.id == null || !serverIds.contains(m.id)))
            .toList();

        state = state.copyWith(messages: [...records, ...pendingLocal]);
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
      int? personnelId, int currentUserId, String currentUserName) {
    if (personnelId == currentUserId) return currentUserName;
    if (personnelId != null && state.memberNameMap.containsKey(personnelId)) {
      return state.memberNameMap[personnelId]!;
    }
    return '用户$personnelId';
  }

  /// 发送文本消息（乐观发送）
  Future<bool> sendMessage({
    required int personnelId,
    required String chatContent,
  }) async {
    final text = chatContent.trim();
    if (text.isEmpty) return false;

    // 生成本地临时 ID
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}_${_localTempCounter++}';

    // 乐观插入：立即显示在列表中
    final optimisticMsg = ChatRecordVo(
      projectId: projectId,
      personnelId: personnelId,
      chatContent: text,
      createTime: DateTime.now().toIso8601String(),
      localTempId: tempId,
      delFlag: 0,
      replyId: state.replyTarget?.id,
      replyContent: state.replyTarget?.chatContent,
      replyUserName: state.replyTarget != null
          ? resolveSenderName(state.replyTarget!.personnelId, personnelId, '')
          : null,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      sendingIds: {...state.sendingIds, tempId},
      clearReplyTarget: true,
    );

    try {
      final res = await _api.sendChatMessage(
        projectId: projectId,
        personnelId: personnelId,
        chatContent: text,
      );
      if (res.isSuccess) {
        // 发送成功：移除 sending 标记，刷新获取服务端消息（含真实 id）
        final newSending = Set<String>.from(state.sendingIds)..remove(tempId);
        state = state.copyWith(sendingIds: newSending);

        // 从服务器刷新以获取真实 ID 和时间戳
        await fetchMessages();
        return true;
      } else {
        // 发送失败：标记为失败
        _markFailed(tempId);
        return false;
      }
    } catch (e) {
      debugPrint('[chat_notifier] sendMessage error: $e');
      if (mounted) _markFailed(tempId);
      return false;
    }
  }

  void _markFailed(String tempId) {
    final newSending = Set<String>.from(state.sendingIds)..remove(tempId);
    final newFailed = Set<String>.from(state.failedIds)..add(tempId);
    state = state.copyWith(sendingIds: newSending, failedIds: newFailed);
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
    int fileType = 1,
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
      final res = await _api.sendChatMessageWithAttachment(
        projectId: projectId,
        personnelId: personnelId,
        imageUrl: imageUrl,
        replyId: state.replyTarget?.id,
        replyContent: state.replyTarget?.chatContent,
      );
      if (res.isSuccess) {
        state = state.copyWith(clearReplyTarget: true);
        await fetchMessages();
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
    int fileType = 1,
  }) async {
    try {
      final res = await _api.sendChatMessageWithAttachment(
        projectId: projectId,
        personnelId: personnelId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        replyId: state.replyTarget?.id,
        replyContent: state.replyTarget?.chatContent,
      );
      if (res.isSuccess) {
        state = state.copyWith(clearReplyTarget: true);
        await fetchMessages();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[chat_notifier] sendFileMessage error: $e');
      return false;
    }
  }

  /// 撤回消息
  Future<bool> revokeMessage(int messageId) async {
    try {
      final res = await _api.revokeChatMessage(messageId);
      if (res.isSuccess) {
        // 本地立即标记为已撤回
        final updated = state.messages.map((m) {
          if (m.id == messageId) return m.copyWith(delFlag: 2);
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
        return true;
      }
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

  /// 开始回复某条消息
  void startReply(ChatRecordVo message) {
    state = state.copyWith(replyTarget: message);
  }

  /// 检查消息是否可撤回（2分钟内）
  bool canRevokeMessage(ChatRecordVo message) {
    if (message.createTime == null) return false;
    final created = DateTime.tryParse(
        message.createTime!.replaceFirst(' ', 'T'));
    if (created == null) return false;
    return DateTime.now().difference(created).inMinutes < 2;
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
