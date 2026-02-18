import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 今日考勤卡片 - 对应 AttendanceCard.vue
class AttendanceCard extends StatelessWidget {
  final bool isLoading;
  final bool hasClockedIn;
  final bool hasClockedOut;
  final String clockInTime;
  final String clockOutTime;
  final String scheduledClockIn;
  final String scheduledClockOut;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    this.isLoading = false,
    this.hasClockedIn = false,
    this.hasClockedOut = false,
    this.clockInTime = '--:--',
    this.clockOutTime = '--:--',
    this.scheduledClockIn = '09:00',
    this.scheduledClockOut = '18:00',
    this.onTap,
  });

  String get _ctaLabel {
    if (hasClockedOut) return '更新下班卡';
    if (hasClockedIn) return '去下班打卡';
    return '去上班打卡';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: isLoading ? _buildSkeleton() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '今日考勤',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              '$scheduledClockIn - $scheduledClockOut',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 打卡时间行
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '上班打卡',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasClockedIn ? clockInTime : '--:--',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasClockedIn ? AppColors.success : AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.separatorNonOpaque,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '下班打卡',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasClockedOut ? clockOutTime : '--:--',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasClockedOut ? AppColors.success : AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // CTA 按钮
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            _ctaLabel,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        _skeletonLine(widthFraction: 0.4, height: 17),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _skeletonLine(height: 28)),
            const SizedBox(width: 12),
            Expanded(child: _skeletonLine(height: 28)),
          ],
        ),
        const SizedBox(height: 12),
        _skeletonLine(height: 44),
      ],
    );
  }

  Widget _skeletonLine({double? widthFraction, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFraction ?? 1.0,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.neutral200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
