import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_models.dart';
import '../../providers/attendance_provider.dart';
import 'calendar_view.dart';
import 'punch_record_card.dart';

/// 统计标签页 - 对应 src/pages/attendance/components/StatsTab.vue
class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  late int _currentYear;
  late int _currentMonth;
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _selectedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    Future.microtask(() => _loadData());
  }

  void _loadData() {
    final lastDay = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final startDate =
        '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-01';
    final endDate =
        '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    ref.read(attendanceProvider.notifier).fetchRecords(startDate, endDate);
    ref.read(attendanceProvider.notifier).fetchMonthlyStats(_currentYear, _currentMonth);
  }

  void _handleMonthChange(int year, int month) {
    setState(() {
      _currentYear = year;
      _currentMonth = month;
      _selectedDate = '';
    });
    _loadData();
  }

  void _handleDateSelect(String date) {
    setState(() => _selectedDate = date);
  }

  DailyAttendance? get _selectedRecord {
    if (_selectedDate.isEmpty) return null;
    final records = ref.read(attendanceProvider).records;
    return records.where((r) => r.date == _selectedDate).firstOrNull;
  }

  int get _attendanceRate {
    final stats = ref.read(attendanceProvider).monthlyStats;
    if (stats == null || stats.requiredWorkDays == 0) return 0;
    return ((stats.actualWorkDays / stats.requiredWorkDays) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(attendanceProvider);

    // 骨架屏
    if (store.isLoading && store.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 空状态
    if (store.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.neutral300),
            const SizedBox(height: 8),
            Text(
              '暂无考勤记录',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              '当月暂无打卡数据',
              style: TextStyle(fontSize: 12, color: AppColors.textQuaternary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 日历视图
          CalendarView(
            records: store.records,
            currentYear: _currentYear,
            currentMonth: _currentMonth,
            onMonthChange: _handleMonthChange,
            onDateSelect: _handleDateSelect,
          ),

          // 出勤率环形进度
          if (store.monthlyStats != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _attendanceRate / 100.0,
                          strokeWidth: 4,
                          backgroundColor: AppColors.neutral200,
                          color: AppColors.primary,
                        ),
                        Text(
                          '$_attendanceRate%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '出勤率',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // 月度统计网格
          if (store.monthlyStats != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _statItem('${store.monthlyStats!.actualWorkDays}', '出勤(天)'),
                  _statItem('${store.monthlyStats!.lateCount}', '迟到',
                      color: AppColors.warning),
                  _statItem('${store.monthlyStats!.earlyLeaveCount}', '早退',
                      color: AppColors.warning),
                  _statItem('${store.monthlyStats!.absentCount}', '缺卡',
                      color: AppColors.error),
                  _statItem('${store.monthlyStats!.absenteeismCount}', '旷工',
                      color: AppColors.error),
                  _statItem(
                    store.monthlyStats!.totalWorkHours.toStringAsFixed(1),
                    '工时(h)',
                  ),
                ],
              ),
            ),

          // 选中日期的打卡详情
          PunchRecordCard(
            record: _selectedRecord,
            selectedDate: _selectedDate.isNotEmpty
                ? _selectedDate
                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {Color? color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
