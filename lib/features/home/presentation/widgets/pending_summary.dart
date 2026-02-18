import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 待办摘要卡片 - 对应 PendingSummary.vue
/// 显示待审批数量 + 未读消息数量
class PendingSummary extends StatelessWidget {
  final int pendingCount;
  final int unreadCount;
  final VoidCallback? onApprovalTap;
  final VoidCallback? onMessageTap;

  const PendingSummary({
    super.key,
    this.pendingCount = 0,
    this.unreadCount = 0,
    this.onApprovalTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.task_outlined,
              iconBgColor: AppColors.primary.withValues(alpha: 0.1),
              iconColor: AppColors.primary,
              label: '待审批',
              count: '$pendingCount项',
              onTap: onApprovalTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              icon: Icons.email_outlined,
              iconBgColor: AppColors.warning.withValues(alpha: 0.1),
              iconColor: AppColors.warning,
              label: '未读消息',
              count: '$unreadCount条',
              onTap: onMessageTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String count;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
