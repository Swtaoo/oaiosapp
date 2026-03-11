import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';
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

enum _StatsViewMode { day, week, month }

class _StatsTabState extends ConsumerState<StatsTab> {
  late int _currentYear;
  late int _currentMonth;
  String _selectedDate = '';
  _StatsViewMode _viewMode = _StatsViewMode.day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _selectedDate = _formatDate(now);
    Future.microtask(_loadDataForCurrentMode);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _defaultSelectedDate(int year, int month) {
    final now = DateTime.now();
    if (now.year == year && now.month == month) {
      return _formatDate(now);
    }
    return '$year-${month.toString().padLeft(2, '0')}-01';
  }

  DateTime _selectedDateTimeOrNow() {
    final parsed = DateTime.tryParse(_selectedDate);
    return parsed ?? DateTime.now();
  }

  int _weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final offset = firstDay.weekday % 7;
    return ((date.day + offset - 1) / 7).floor() + 1;
  }

  String _weekRangeText(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final start = '${weekStart.month}/${weekStart.day}';
    final end = '${weekEnd.month}/${weekEnd.day}';
    return '$start - $end';
  }

  Future<void> _loadDataForCurrentMode() async {
    final lastDay = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final startDate =
        '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-01';
    final endDate =
        '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final notifier = ref.read(attendanceProvider.notifier);
    await Future.wait([
      notifier.fetchRecords(startDate, endDate),
      notifier.fetchMonthlyStats(_currentYear, _currentMonth),
    ]);

    if (_viewMode == _StatsViewMode.week) {
      final selected = _selectedDateTimeOrNow();
      await notifier.fetchWeeklyStats(
        selected.year,
        selected.month,
        _weekOfMonth(selected),
      );
      return;
    }

    await notifier.fetchMonthlyDetailedStats(_currentYear, _currentMonth);
  }

  void _handleMonthChange(int year, int month) {
    setState(() {
      _currentYear = year;
      _currentMonth = month;
      _selectedDate = _defaultSelectedDate(year, month);
    });
    _loadDataForCurrentMode();
  }

  void _handleDateSelect(String date) {
    setState(() => _selectedDate = date);
    if (_viewMode == _StatsViewMode.week) {
      _loadDataForCurrentMode();
    }
  }

  void _switchMode(_StatsViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    _loadDataForCurrentMode();
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentYear = now.year;
      _currentMonth = now.month;
      _selectedDate = _formatDate(now);
    });
    _loadDataForCurrentMode();
  }

  void _jumpToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _currentYear = now.year;
      _currentMonth = now.month;
      _selectedDate = _defaultSelectedDate(now.year, now.month);
    });
    _loadDataForCurrentMode();
  }

  DailyAttendance? get _selectedRecord {
    if (_selectedDate.isEmpty) return null;
    final records = ref.read(attendanceProvider).records;
    return records.where((r) => r.date == _selectedDate).firstOrNull;
  }

  bool get _isSelectedRestDay {
    final record = _selectedRecord;
    if (record == null) return false;
    return record.scheduleType == 'rest' || record.scheduleType == 'holiday';
  }

  @override
  Widget build(BuildContext context) {
    // 打卡完成后，统计页需要实时刷新（IndexedStack 下不会重新 initState）
    // 监听本地打卡缓存变化，触发当前月份的记录/月度统计重新拉取
    ref.listen(
      attendanceProvider.select(
        (s) => (
          s.localPunchData.lastPunchDate,
          s.localPunchData.morningTime,
          s.localPunchData.eveningTime,
          s.localPunchData.morningPunch,
          s.localPunchData.eveningPunch,
        ),
      ),
      (prev, next) {
        final dateStr = next.$1;
        if (dateStr.isEmpty) return;
        final parts = dateStr.split('-');
        if (parts.length < 2) return;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) return;
        if (year == _currentYear && month == _currentMonth) {
          _loadDataForCurrentMode();
        }
      },
    );

    final store = ref.watch(attendanceProvider);
    final user = ref.watch(currentUserProvider);

    // 骨架屏
    if (store.isLoading && store.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildProfileAndModeCard(user, store.rule),
          const SizedBox(height: 10),
          if (_viewMode == _StatsViewMode.day) _buildDayView(store),
          if (_viewMode == _StatsViewMode.week) _buildWeekView(store),
          if (_viewMode == _StatsViewMode.month) _buildMonthView(store),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileAndModeCard(UserInfo? user, AttendanceRule rule) {
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : '未命名用户';
    final companyName = rule.companyName.trim().isNotEmpty
        ? rule.companyName
        : '暂无公司信息';
    final firstChar = displayName.isNotEmpty ? displayName[0] : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              firstChar,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/regulation'),
                      child: Text(
                        '（查看规则）',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildModeSwitch(),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeChip(label: '日', mode: _StatsViewMode.day),
          _modeChip(label: '周', mode: _StatsViewMode.week),
          _modeChip(label: '月', mode: _StatsViewMode.month),
        ],
      ),
    );
  }

  Widget _modeChip({required String label, required _StatsViewMode mode}) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDayView(AttendanceState store) {
    final selectedDate = _selectedDate.isNotEmpty
        ? _selectedDate
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selected = _selectedDateTimeOrNow();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                '${selected.year}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _jumpToToday,
                child: Text(
                  '回到今天',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        CalendarView(
          records: store.records,
          currentYear: _currentYear,
          currentMonth: _currentMonth,
          onMonthChange: _handleMonthChange,
          onDateSelect: _handleDateSelect,
        ),
        if (_isSelectedRestDay)
          _buildRestDayCard(selectedDate)
        else
          PunchRecordCard(record: _selectedRecord, selectedDate: selectedDate),
      ],
    );
  }

  Widget _buildWeekView(AttendanceState store) {
    final selected = _selectedDateTimeOrNow();
    final weekNo = _weekOfMonth(selected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Row(
            children: [
              Text(
                '${selected.year}年${selected.month}月 第$weekNo周',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _weekRangeText(selected),
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailedStatsGrid(
            detailedStats: store.detailedStats,
            fallbackMonthly: store.monthlyStats,
          ),
          const SizedBox(height: 8),
          Text(
            '统计截至 ${_statsTimeText(store.detailedStats)}',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(AttendanceState store) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Row(
            children: [
              Text(
                '$_currentYear',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_currentMonth月',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _jumpToCurrentMonth,
                child: Text(
                  '回到本月',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(12, (index) {
                final month = index + 1;
                final selected = month == _currentMonth;
                return GestureDetector(
                  onTap: () => _handleMonthChange(_currentYear, month),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: EdgeInsets.only(right: month == 12 ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$month月',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.separatorNonOpaque),
          const SizedBox(height: 12),
          _buildDetailedStatsGrid(
            detailedStats: store.detailedStats,
            fallbackMonthly: store.monthlyStats,
          ),
          const SizedBox(height: 10),
          Text(
            '统计截至 ${_statsTimeText(store.detailedStats)}',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.separatorNonOpaque),
          TextButton(
            onPressed: () => _switchMode(_StatsViewMode.day),
            child: Text(
              '查看详情',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsGrid({
    required PeriodStats? detailedStats,
    required MonthlyStats? fallbackMonthly,
  }) {
    if (detailedStats == null && fallbackMonthly == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '暂无统计数据',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final metrics = <_MetricItem>[
      _MetricItem(
        label: '平均工时',
        value: detailedStats != null
            ? detailedStats.averageWorkHours.toStringAsFixed(1)
            : fallbackMonthly!.averageWorkHours.toStringAsFixed(1),
      ),
      _MetricItem(
        label: '出勤天数',
        value: detailedStats != null
            ? '${detailedStats.actualWorkDays}'
            : '${fallbackMonthly!.actualWorkDays}',
      ),
      _MetricItem(
        label: '出勤班次',
        value: detailedStats != null
            ? '${detailedStats.workShiftCount}'
            : '${fallbackMonthly!.totalWorkDays}',
      ),
      _MetricItem(
        label: '休息天数',
        value: detailedStats != null ? '${detailedStats.restDays}' : '--',
      ),
      _MetricItem(
        label: '迟到',
        value: detailedStats != null
            ? '${detailedStats.lateCount}'
            : '${fallbackMonthly!.lateCount}',
        type: _MetricType.warning,
      ),
      _MetricItem(
        label: '早退',
        value: detailedStats != null
            ? '${detailedStats.earlyLeaveCount}'
            : '${fallbackMonthly!.earlyLeaveCount}',
        type: _MetricType.warning,
      ),
      _MetricItem(
        label: '缺卡',
        value: detailedStats != null
            ? '${detailedStats.absentCount}'
            : '${fallbackMonthly!.absentCount}',
        type: _MetricType.error,
      ),
      _MetricItem(
        label: '旷工',
        value: detailedStats != null
            ? '${detailedStats.absenteeismCount}'
            : '--',
      ),
      _MetricItem(
        label: '外勤',
        value: detailedStats != null ? '${detailedStats.fieldWorkCount}' : '--',
      ),
      _MetricItem(
        label: '加班',
        value: detailedStats != null
            ? detailedStats.overtimeHours.toStringAsFixed(1)
            : fallbackMonthly!.overtimeHours.toStringAsFixed(1),
      ),
      _MetricItem(
        label: '补卡申请',
        value: detailedStats != null
            ? '${detailedStats.makeupPunchCount}'
            : '--',
      ),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final valueAsNum = num.tryParse(metric.value);
        final hasValue = valueAsNum == null || valueAsNum > 0;

        Color valueColor = hasValue
            ? AppColors.textPrimary
            : AppColors.textQuaternary;
        if (hasValue && metric.type == _MetricType.warning) {
          valueColor = AppColors.warning;
        }
        if (hasValue && metric.type == _MetricType.error) {
          valueColor = AppColors.error;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric.value,
              style: TextStyle(
                fontSize: 40 / 2,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        );
      },
    );
  }

  String _statsTimeText(PeriodStats? detailedStats) {
    if (detailedStats != null &&
        detailedStats.statisticsTime.trim().isNotEmpty) {
      return detailedStats.statisticsTime;
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  }

  Widget _buildRestDayCard(String selectedDate) {
    return Container(
      margin: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedDate,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Divider(height: 20, color: AppColors.separatorNonOpaque),
          Text(
            '当日班次：休息',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '出勤统计：打卡0次',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '好好休息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MetricType { normal, warning, error }

class _MetricItem {
  final String label;
  final String value;
  final _MetricType type;

  const _MetricItem({
    required this.label,
    required this.value,
    this.type = _MetricType.normal,
  });
}
