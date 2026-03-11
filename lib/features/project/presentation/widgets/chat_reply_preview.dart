import 'package:flutter/material.dart';

/// 回复引用预览（气泡内）
/// 左侧竖线 + 被引用用户名 + 引用内容摘要
class ChatReplyPreview extends StatelessWidget {
  final String? replyUserName;
  final String? replyContent;
  final bool isOwn;

  /// 点击引用区域的回调（跳转到被引用消息）
  final VoidCallback? onTap;

  const ChatReplyPreview({
    super.key,
    this.replyUserName,
    this.replyContent,
    this.isOwn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (replyContent == null || replyContent!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isOwn
                  ? const Color(0xFF5AB842)
                  : const Color(0xFFCCCCCC),
              width: 2,
            ),
          ),
          color: isOwn
              ? const Color(0xFF80D956).withValues(alpha: 0.3)
              : const Color(0xFFF0F0F0),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyUserName != null && replyUserName!.isNotEmpty)
              Text(
                replyUserName!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isOwn
                      ? const Color(0xFF3D8C27)
                      : const Color(0xFF576B95),
                ),
              ),
            Text(
              replyContent!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isOwn
                    ? const Color(0xFF333333)
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
