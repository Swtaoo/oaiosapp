import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../theme/chat_colors.dart';
import 'unread_badge.dart';

/// 企微风格会话列表项
class ConversationListItem extends StatelessWidget {
  final String projectName;
  final String? projectDescription;
  final String? managerName;
  final String? expectedDeliveryTime;
  final String? lastContent;
  final String? lastSenderName;
  final int? lastTimestamp;
  final int unreadCount;
  final VoidCallback? onTap;

  const ConversationListItem({
    super.key,
    required this.projectName,
    this.projectDescription,
    this.managerName,
    this.expectedDeliveryTime,
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

    // 构造标签列表: 负责人 / 到期时间
    final tags = <_TagInfo>[];
    if (managerName != null && managerName!.isNotEmpty) {
      tags.add(_TagInfo(Icons.person_outline, '负责人: $managerName'));
    }
    if (expectedDeliveryTime != null && expectedDeliveryTime!.isNotEmpty) {
      final dateStr = _formatDate(expectedDeliveryTime!);
      tags.add(_TagInfo(Icons.schedule, '到期: $dateStr', color: _deadlineColor(expectedDeliveryTime!)));
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像: 52x52 圆角矩形
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
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
                  // 第一行: 项目名 + 最后消息时间
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
                  // 第二行: 项目描述（最多2行，超出显示...）
                  if (projectDescription != null && projectDescription!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      projectDescription!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // 第三行: 标签（负责人 + 到期时间）
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: tags.map((t) => _buildTag(t)).toList(),
                    ),
                  ],
                  // 第四行: 最后消息摘要 + 未读徽章
                  if (summary.isNotEmpty || unreadCount > 0) ...[
                    const SizedBox(height: 4),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(_TagInfo tag) {
    final color = tag.color ?? const Color(0xFF999999);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(tag.icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          tag.text,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  String _buildSummary() {
    if (lastContent == null || lastContent!.isEmpty) return '';
    if (lastSenderName != null && lastSenderName!.isNotEmpty) {
      return '$lastSenderName: $lastContent';
    }
    return lastContent!;
  }

  /// 截取日期部分（去掉时分秒）
  String _formatDate(String dateTime) {
    if (dateTime.length >= 10) return dateTime.substring(0, 10);
    return dateTime;
  }

  /// 根据距离到期日远近返回颜色
  Color? _deadlineColor(String dateTime) {
    final date = DateTime.tryParse(dateTime);
    if (date == null) return null;
    final daysLeft = date.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return const Color(0xFFE53935); // 已过期 - 红色
    if (daysLeft <= 7) return const Color(0xFFFF9800); // 7天内 - 橙色
    return null;
  }
}

class _TagInfo {
  final IconData icon;
  final String text;
  final Color? color;
  const _TagInfo(this.icon, this.text, {this.color});
}
