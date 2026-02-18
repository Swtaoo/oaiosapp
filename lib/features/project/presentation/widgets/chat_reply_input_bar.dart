import 'package:flutter/material.dart';

import '../theme/chat_colors.dart';

/// 回复预览条（输入栏上方）
/// [左竖线] "回复 XXX: 内容..." [X关闭]
class ChatReplyInputBar extends StatelessWidget {
  final String? replyUserName;
  final String? replyContent;
  final VoidCallback onClose;

  const ChatReplyInputBar({
    super.key,
    this.replyUserName,
    this.replyContent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: ChatColors.sendBtnActive,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '回复 ${replyUserName ?? ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF576B95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (replyContent != null && replyContent!.isNotEmpty)
                  Text(
                    replyContent!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }
}
