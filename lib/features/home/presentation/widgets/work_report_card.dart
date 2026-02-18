import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 工作汇报卡片 - 对应 WorkReportCard.vue
class WorkReportCard extends StatelessWidget {
  final List<WorkReportItem> reports;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final void Function(String id)? onItemTap;

  const WorkReportCard({
    super.key,
    this.reports = const [],
    this.isLoading = false,
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
                '工作汇报',
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
            child: isLoading
                ? _buildSkeleton()
                : reports.isEmpty
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
            Icon(Icons.description_outlined, size: 48, color: AppColors.neutral300),
            const SizedBox(height: 8),
            Text(
              '暂无工作汇报',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: List.generate(reports.length, (index) {
        final report = reports[index];
        final isLast = index == reports.length - 1;
        return GestureDetector(
          onTap: () => onItemTap?.call(report.id),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _PeriodTag(period: report.period),
                          const SizedBox(width: 6),
                          Text(
                            report.dateLabel,
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u203A',
                  style: TextStyle(fontSize: 18, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity * 0.6,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PeriodTag extends StatelessWidget {
  final String period;

  const _PeriodTag({required this.period});

  static const _periodLabels = {
    'weekly': '周报',
    'monthly': '月报',
    'yearly': '年报',
  };

  Color get _bgColor {
    switch (period) {
      case 'weekly':
        return AppColors.primary.withValues(alpha: 0.1);
      case 'monthly':
        return AppColors.warning.withValues(alpha: 0.1);
      case 'yearly':
        return AppColors.success.withValues(alpha: 0.1);
      default:
        return AppColors.neutral200;
    }
  }

  Color get _textColor {
    switch (period) {
      case 'weekly':
        return AppColors.primary;
      case 'monthly':
        return AppColors.warning;
      case 'yearly':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        _periodLabels[period] ?? '汇报',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _textColor),
      ),
    );
  }
}

class WorkReportItem {
  final String id;
  final String title;
  final String period;
  final String dateLabel;

  const WorkReportItem({
    required this.id,
    required this.title,
    required this.period,
    required this.dateLabel,
  });
}
