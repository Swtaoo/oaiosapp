import 'package:flutter/material.dart';

import '../../data/models/project_models.dart';
import '../theme/chat_colors.dart';
import 'chat_attachment_panel.dart';
import 'chat_reply_input_bar.dart';

/// 企微风格增强输入栏 V2
/// 布局: [语音占位] [多行输入框] [表情占位] [+附件/发送按钮]
class ChatInputBarV2 extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final ChatRecordVo? replyTarget;
  final String? replyTargetSenderName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onPickFile;

  const ChatInputBarV2({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.replyTarget,
    this.replyTargetSenderName,
    this.onCancelReply,
    this.onPickImage,
    this.onTakePhoto,
    this.onPickFile,
  });

  @override
  State<ChatInputBarV2> createState() => _ChatInputBarV2State();
}

class _ChatInputBarV2State extends State<ChatInputBarV2> {
  bool _showAttachmentPanel = false;
  bool _hasText = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _toggleAttachmentPanel() {
    if (_showAttachmentPanel) {
      setState(() => _showAttachmentPanel = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showAttachmentPanel = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 回复预览条
        if (widget.replyTarget != null)
          ChatReplyInputBar(
            replyUserName: widget.replyTargetSenderName,
            replyContent: widget.replyTarget!.chatContent,
            onClose: widget.onCancelReply ?? () {},
          ),
        // 输入栏
        Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: _showAttachmentPanel
                ? 8
                : 8 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: ChatColors.inputBarBg,
            border: Border(
              top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 语音占位按钮
              _buildIconButton(Icons.mic_none, () {}),
              const SizedBox(width: 4),
              // 多行输入框
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ChatColors.inputBarBorder,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      hintStyle: TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (_hasText) widget.onSend();
                    },
                    onTap: () {
                      if (_showAttachmentPanel) {
                        setState(() => _showAttachmentPanel = false);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 表情占位按钮
              _buildIconButton(Icons.emoji_emotions_outlined, () {}),
              const SizedBox(width: 4),
              // + / 发送按钮
              _hasText
                  ? _buildSendButton()
                  : _buildIconButton(Icons.add_circle_outline, _toggleAttachmentPanel),
            ],
          ),
        ),
        // 附件面板
        if (_showAttachmentPanel)
          SafeArea(
            top: false,
            child: ChatAttachmentPanel(
              onPickImage: () {
                setState(() => _showAttachmentPanel = false);
                widget.onPickImage?.call();
              },
              onTakePhoto: () {
                setState(() => _showAttachmentPanel = false);
                widget.onTakePhoto?.call();
              },
              onPickFile: () {
                setState(() => _showAttachmentPanel = false);
                widget.onPickFile?.call();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 24, color: const Color(0xFF555555)),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: widget.isSending ? null : widget.onSend,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.isSending
              ? ChatColors.sendBtnDisabled
              : ChatColors.sendBtnActive,
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.isSending
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send, size: 18, color: Colors.white),
      ),
    );
  }
}
