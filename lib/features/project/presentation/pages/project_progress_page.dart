// 项目进度聊天页 - 企微风格
// Phase 3: 灰色背景 + 时间分隔线 + 消息状态

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/project_models.dart';
import '../../providers/chat_providers.dart';
import '../theme/chat_colors.dart';
import '../widgets/chat_input_bar_v2.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_message_menu.dart';
import '../widgets/chat_time_separator.dart';
import '../widgets/project_members_sheet.dart';

class ProjectProgressPage extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectProgressPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProjectProgressPage> createState() =>
      _ProjectProgressPageState();
}

class _ProjectProgressPageState extends ConsumerState<ProjectProgressPage>
    with WidgetsBindingObserver {
  final _inputCtl = TextEditingController();
  final _itemScrollCtl = ItemScrollController();
  final _imagePicker = ImagePicker();
  int _prevMessageCount = 0;

  /// 当前高亮的消息 ID（点击引用后短暂高亮）
  int? _highlightedMessageId;

  int get _currentUserId =>
      ref.read(currentUserProvider)?.effectiveUserId ?? 0;
  String get _currentUserName =>
      ref.read(currentUserProvider)?.displayName ?? '我';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    if (state == AppLifecycleState.resumed) {
      // 恢复"正在查看"标记，抑制前台时的本地通知
      notifier.setCurrentViewingProject(widget.projectId);
      notifier.fetchMessages();
      notifier.startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // 清除"正在查看"标记，允许后台时触发本地通知
      notifier.clearCurrentViewingProject();
      notifier.stopAutoRefresh();
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;

    _inputCtl.clear();
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    final atPersonnelIds = notifier.extractAtPersonnelIds(text);
    final success = await notifier.sendMessage(
      personnelId: _currentUserId,
      chatContent: text,
      atPersonnelIds: atPersonnelIds,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发送失败')),
      );
    }
  }

  /// 从相册选择图片并发送
  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    await _uploadAndSendImage(image.path, image.name);
  }

  /// 拍照并发送
  Future<void> _takePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;
    await _uploadAndSendImage(photo.path, photo.name);
  }

  /// 上传图片并发送
  Future<void> _uploadAndSendImage(String path, String name) async {
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    final success = await notifier.uploadAndSendImage(
      personnelId: _currentUserId,
      filePath: path,
      fileName: name,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片发送失败')),
      );
    }
  }

  /// 选择文件并发送
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    final success = await notifier.uploadAndSendFile(
      personnelId: _currentUserId,
      filePath: path,
      fileName: file.name,
      fileSize: file.size,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件发送失败')),
      );
    }
  }

  /// reverse 模式下，index 0 = 底部（最新消息）
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollCtl.isAttached) {
        _itemScrollCtl.jumpTo(index: 0);
      }
    });
  }

  /// 滚动到指定消息并高亮
  void _scrollToMessage(int messageId) {
    final messages = ref.read(chatNotifierProvider(widget.projectId)).messages;
    final msgIndex = messages.indexWhere((m) => m.id == messageId);
    if (msgIndex < 0) return;

    final listIndex = _messageIndexToListIndex(msgIndex, messages);
    final totalItems = _calculateItemCount(messages);
    // reverse 模式: builder index = totalItems - 1 - forwardIndex
    final reverseIndex = totalItems - 1 - listIndex;

    _itemScrollCtl.scrollTo(
      index: reverseIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.3,
    ).then((_) => _highlightMessage(messageId));
  }

  /// 短暂高亮指定消息
  void _highlightMessage(int messageId) {
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  /// 将消息数组下标转为 ListView 的 item index（含时间分隔线）
  int _messageIndexToListIndex(int msgIndex, List messages) {
    int listIndex = 0;
    for (int i = 0; i <= msgIndex; i++) {
      final needSep = i == 0 || shouldShowTimeSeparator(
        messages[i - 1].createTime,
        messages[i].createTime,
      );
      if (needSep) listIndex++; // 时间分隔线
      if (i == msgIndex) return listIndex;
      listIndex++; // 消息本身
    }
    return listIndex;
  }

  void _showMembersDialog() {
    final chatState = ref.read(chatNotifierProvider(widget.projectId));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProjectMembersSheet(members: chatState.members),
    );
  }

  /// 处理消息菜单操作
  void _handleMessageAction(ChatMessageAction action, ChatRecordVo msg) {
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    switch (action) {
      case ChatMessageAction.copy:
        if (msg.chatContent != null) {
          copyMessageText(context, msg.chatContent!);
        }
      case ChatMessageAction.reply:
        notifier.startReply(msg);
      case ChatMessageAction.forward:
        // TODO: 转发功能
        break;
      case ChatMessageAction.delete:
        if (msg.id != null) notifier.removeLocalMessage(msg.id!);
      case ChatMessageAction.revoke:
        if (msg.id != null) {
          notifier.revokeMessage(msg.id!, _currentUserId).then((success) {
            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('撤回失败')),
              );
            }
          });
        }
    }
  }

  /// 显示消息长按菜单
  void _showMessageMenu(BuildContext context, ChatRecordVo msg, LongPressStartDetails details) {
    final isOwn = msg.personnelId == _currentUserId;
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);
    showChatMessageMenu(
      context: context,
      position: details.globalPosition,
      isOwn: isOwn,
      canRevoke: isOwn && notifier.canRevokeMessage(msg),
      textContent: msg.chatContent,
      onAction: (action) => _handleMessageAction(action, msg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(widget.projectId));
    final notifier = ref.read(chatNotifierProvider(widget.projectId).notifier);

    // reverse 模式: 初始位置已在底部，只需处理新消息到达时的自动滚动
    if (!chatState.isLoading) {
      if (_prevMessageCount > 0 && chatState.messages.length > _prevMessageCount) {
        _scrollToBottom();
      }
      _prevMessageCount = chatState.messages.length;
    }

    // 构建带时间分隔线的消息列表
    final messages = chatState.messages;

    // 构建成员姓名集合，用于 @提及高亮
    final memberNames = chatState.members
        .where((m) => m.name != null && m.name!.isNotEmpty)
        .map((m) => m.name!)
        .toSet();

    return Scaffold(
      backgroundColor: ChatColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.projectName.isNotEmpty ? widget.projectName : '项目进度讨论'}'
          '${chatState.members.isNotEmpty ? '(${chatState.members.length})' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: _showMembersDialog,
          ),
        ],
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Builder(builder: (context) {
                    final itemCount = _calculateItemCount(messages);
                    return ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollCtl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // reverse 模式: index 0 在底部，需要映射回正序索引
                        final forwardIndex = itemCount - 1 - index;
                        return _buildItem(forwardIndex, messages, chatState, notifier, memberNames);
                      },
                    );
                  }),
                ),
                ChatInputBarV2(
                  controller: _inputCtl,
                  isSending: chatState.isSending,
                  onSend: _sendMessage,
                  members: chatState.members,
                  replyTarget: chatState.replyTarget,
                  replyTargetSenderName: chatState.replyTarget != null
                      ? notifier.resolveSenderName(
                          chatState.replyTarget!.personnelId,
                          _currentUserId,
                          _currentUserName,
                          personnelName: chatState.replyTarget!.personnelName,
                        )
                      : null,
                  onCancelReply: () => notifier.cancelReply(),
                  onPickImage: _pickImage,
                  onTakePhoto: _takePhoto,
                  onPickFile: _pickFile,
                ),
              ],
            ),
    );
  }

  /// 计算列表项总数（消息 + 时间分隔线）
  int _calculateItemCount(List messages) {
    if (messages.isEmpty) return 0;
    int count = messages.length;
    for (int i = 0; i < messages.length; i++) {
      if (i == 0 || shouldShowTimeSeparator(
        messages[i - 1].createTime,
        messages[i].createTime,
      )) {
        count++;
      }
    }
    return count;
  }

  /// 构建列表项（时间分隔线或消息气泡）
  Widget _buildItem(int index, List messages, chatState, notifier, Set<String> memberNames) {
    // 遍历消息，计算实际位置
    int itemIndex = 0;
    for (int i = 0; i < messages.length; i++) {
      final needSeparator = i == 0 || shouldShowTimeSeparator(
        messages[i - 1].createTime,
        messages[i].createTime,
      );

      if (needSeparator) {
        if (itemIndex == index) {
          return ChatTimeSeparator(
            timeText: formatChatGroupTime(messages[i].createTime),
          );
        }
        itemIndex++;
      }

      if (itemIndex == index) {
        final msg = messages[i];
        final msgId = msg.id;
        final isOwn = msg.personnelId == _currentUserId;

        final bubble = ChatMessageBubble(
          senderName: notifier.resolveSenderName(
            msg.personnelId,
            _currentUserId,
            _currentUserName,
            personnelName: msg.personnelName,
          ),
          content: msg.chatContent ?? '',
          timeText: formatChatTime(msg.createTime),
          isOwn: isOwn,
          imageUrl: msg.imageUrl ?? msg.fileUrl,
          message: msg,
          memberNames: memberNames,
          onReplyTap: msg.replyId != null && msg.replyId! > 0
              ? () => _scrollToMessage(msg.replyId!)
              : null,
        );

        final isHighlighted = _highlightedMessageId == msgId;

        // 右滑回复手势 + 长按菜单
        return Dismissible(
          key: ValueKey(msg.id ?? index),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (_) async {
            notifier.startReply(msg);
            return false; // 不真正移除
          },
          background: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.reply, color: Color(0xFF999999), size: 22),
            ),
          ),
          child: GestureDetector(
            onLongPressStart: (details) => _showMessageMenu(context, msg, details),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFF07C160).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: bubble,
            ),
          ),
        );
      }
      itemIndex++;
    }
    return const SizedBox.shrink();
  }
}
