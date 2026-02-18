import 'package:flutter/material.dart';

import '../theme/chat_colors.dart';

/// 撤回消息提示
/// 居中灰字: "你撤回了一条消息" / "XXX撤回了一条消息"
class ChatRevokedMessage extends StatelessWidget {
  final bool isOwn;
  final String? senderName;

  const ChatRevokedMessage({
    super.key,
    this.isOwn = false,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final text = isOwn ? '你撤回了一条消息' : '${senderName ?? "对方"}撤回了一条消息';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: ChatColors.revokedText,
          ),
        ),
      ),
    );
  }
}
