import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../data/models/attendance_models.dart';

/// 打卡记录卡片 - 对应 src/pages/attendance/components/PunchRecordCard.vue
class PunchRecordCard extends StatelessWidget {
  final DailyAttendance? record;
  final String selectedDate;
  final EdgeInsetsGeometry margin;

  const PunchRecordCard({
    super.key,
    this.record,
    required this.selectedDate,
    this.margin = const EdgeInsets.all(12),
  });

  static const _statusLabels = {
    'normal': '正常',
    'late': '迟到',
    'early': '早退',
    'absent': '缺卡',
  };

  static const _anomalyLabels = {
    'late': '迟到',
    'early': '早退',
    'missing_clock_in': '上班缺卡',
    'missing_clock_out': '下班缺卡',
  };

  Color _statusColor(String? status) {
    switch (status) {
      case 'normal':
        return AppColors.success;
      case 'late':
      case 'early':
        return AppColors.warning;
      case 'absent':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status) {
      case 'normal':
        return const Color(0xFFE8FBE8);
      case 'late':
      case 'early':
        return const Color(0xFFFFF5EB);
      case 'absent':
        return const Color(0xFFFFF0F0);
      default:
        return AppColors.neutral200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部: 日期 + 异常标签
          Row(
            children: [
              Text(
                selectedDate,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (record?.anomalies.isNotEmpty == true)
                ...record!.anomalies.map((a) {
                  final isMissing = a.startsWith('missing_');
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMissing
                          ? const Color(0xFFFFF0F0)
                          : const Color(0xFFFFF5EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _anomalyLabels[a] ?? a,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMissing ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  );
                }),
            ],
          ),
          Divider(height: 20, color: AppColors.separatorNonOpaque),

          if (record != null) ...[
            // 上班记录
            _buildRecordItem(label: '上班打卡', punchRecord: record!.clockInRecord),
            const SizedBox(height: 10),
            // 下班记录
            _buildRecordItem(
              label: '下班打卡',
              punchRecord: record!.clockOutRecord,
            ),
            // 工时
            if (record!.workHours > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.separatorNonOpaque,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    '工作时长: ${record!.workHours.toStringAsFixed(1)}小时',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无打卡记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textQuaternary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required String label,
    required AttendancePunchRecord? punchRecord,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        if (punchRecord != null)
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                app_date.extractTimeShort(
                  DateTime.tryParse(punchRecord.punchTime) ?? DateTime.now(),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Mono',
                ),
              ),
              if (punchRecord.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBgColor(punchRecord.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _statusLabels[punchRecord.status] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(punchRecord.status),
                    ),
                  ),
                ),
              Text(
                punchRecord.punchLocation,
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              if (punchRecord.punchType == 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '外勤',
                    style: TextStyle(fontSize: 10, color: AppColors.warning),
                  ),
                ),
            ],
          )
        else
          Text(
            '未打卡',
            style: TextStyle(fontSize: 14, color: AppColors.textQuaternary),
          ),
      ],
    );
  }
}
