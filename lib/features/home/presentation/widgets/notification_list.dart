import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;

/// 通知列表 - 对应 NotificationList.vue
class NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  final VoidCallback? onViewAll;
  final void Function(NotificationItem)? onItemTap;

  const NotificationList({
    super.key,
    this.notifications = const [],
    this.onViewAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '项目消息',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '查看全部',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 消息卡片
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: notifications.isEmpty
                ? _buildEmpty()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_outlined, size: 48, color: AppColors.neutral300),
            const SizedBox(height: 8),
            Text(
              '暂无项目消息',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: List.generate(notifications.length, (index) {
        final item = notifications[index];
        final isLast = index == notifications.length - 1;
        return GestureDetector(
          onTap: () => onItemTap?.call(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppColors.separatorNonOpaque,
                        width: 0.5,
                      ),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.projectName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(item.timestamp),
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.senderName}：${item.content}',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return date_utils.formatRelativeTime(dt);
  }
}

/// 通知数据模型
class NotificationItem {
  final int projectId;
  final String projectName;
  final String content;
  final String senderName;
  final int timestamp;

  const NotificationItem({
    required this.projectId,
    required this.projectName,
    required this.content,
    required this.senderName,
    required this.timestamp,
  });
}
