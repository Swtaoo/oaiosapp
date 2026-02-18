import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../theme/chat_colors.dart';
import 'unread_badge.dart';

/// 企微风格会话列表项
class ConversationListItem extends StatelessWidget {
  final String projectName;
  final String? lastContent;
  final String? lastSenderName;
  final int? lastTimestamp;
  final int unreadCount;
  final VoidCallback? onTap;

  const ConversationListItem({
    super.key,
    required this.projectName,
    this.lastContent,
    this.lastSenderName,
    this.lastTimestamp,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        projectName.isNotEmpty ? projectName.characters.first : '?';
    final timeText =
        lastTimestamp != null ? formatConversationTime(lastTimestamp!) : '';
    final summary = _buildSummary();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 头像: 48x48 圆角矩形
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 内容区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行: 项目名 + 时间
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111111),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ChatColors.timeSeparator,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 第二行: 最后消息摘要 + 未读徽章
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        UnreadBadge(count: unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSummary() {
    if (lastContent == null || lastContent!.isEmpty) return '';
    if (lastSenderName != null && lastSenderName!.isNotEmpty) {
      return '$lastSenderName: $lastContent';
    }
    return lastContent!;
  }
}
