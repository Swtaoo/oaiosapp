import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_models.dart';
import '../../providers/attendance_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/punch_record_card.dart';

/// 成员考勤详情页
/// 使用与“个人统计”一致的 UI 和统计口径，打开即展示当前选中成员统计。
class MemberDetailPage extends ConsumerStatefulWidget {
  final int userId;
  final int initialYear;
  final int initialMonth;

  const MemberDetailPage({
    super.key,
    required this.userId,
    this.initialYear = 0,
    this.initialMonth = 0,
  });

  @override
  ConsumerState<MemberDetailPage> createState() => _MemberDetailPageState();
}

enum _StatsViewMode { day, week, month }

class _MemberDetailPageState extends ConsumerState<MemberDetailPage> {
  late int _currentYear;
  late int _currentMonth;
  String _selectedDate = '';
  _StatsViewMode _viewMode = _StatsViewMode.day;
  bool _isLoading = false;

  MemberInfo? _memberInfo;
  List<DailyAttendance> _records = [];
  MonthlyStats? _monthlyStats;
  PeriodStats? _detailedStats;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = widget.initialYear > 0 ? widget.initialYear : now.year;
    _currentMonth = widget.initialMonth > 0 ? widget.initialMonth : now.month;
    _selectedDate = _defaultSelectedDate(_currentYear, _currentMonth);
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
    if (widget.userId <= 0) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(attendanceApiProvider);
      final lastDay = DateTime(_currentYear, _currentMonth + 1, 0).day;
      final startDate =
          '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-01';
      final endDate =
          '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      // 并行请求成员资料、日历记录与统计数据，保证页面首屏和统计口径同步。
      final memberDetailFuture = api.getMemberDetail(
        userId: widget.userId,
        year: _currentYear,
        month: _currentMonth,
        endDate: endDate,
      );
      final recordsFuture = api.getRecords(
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      );
      final monthlyStatsFuture = api.getMonthlyStats(
        userId: widget.userId,
        year: _currentYear,
        month: _currentMonth,
      );
      final detailedStatsFuture = _viewMode == _StatsViewMode.week
          ? api.getWeeklyStats(
              userId: widget.userId,
              year: _currentYear,
              month: _currentMonth,
              weekOfMonth: _weekOfMonth(_selectedDateTimeOrNow()),
            )
          : api.getMonthlyDetailedStats(
              userId: widget.userId,
              year: _currentYear,
              month: _currentMonth,
            );

      final memberDetailRes = await memberDetailFuture;
      final recordsRes = await recordsFuture;
      final monthlyStatsRes = await monthlyStatsFuture;
      final detailedStatsRes = await detailedStatsFuture;

      if (!mounted) return;

      setState(() {
        _memberInfo = memberDetailRes.isSuccess && memberDetailRes.data != null
            ? memberDetailRes.data!.memberInfo
            : _memberInfo;
        _records =
            recordsRes.isSuccess && recordsRes.data != null ? recordsRes.data! : [];
        _monthlyStats = monthlyStatsRes.isSuccess && monthlyStatsRes.data != null
            ? monthlyStatsRes.data
            : null;
        _detailedStats =
            detailedStatsRes.isSuccess && detailedStatsRes.data != null
                ? detailedStatsRes.data
                : null;
      });
    } catch (e) {
      debugPrint('[member_detail_page] Error: $e');
      if (!mounted) return;
      setState(() {
        _records = [];
        _monthlyStats = null;
        _detailedStats = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return _records.where((r) => r.date == _selectedDate).firstOrNull;
  }

  bool get _isSelectedRestDay {
    final record = _selectedRecord;
    if (record == null) return false;
    return record.scheduleType == 'rest' || record.scheduleType == 'holiday';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('成员考勤详情')),
      body: widget.userId <= 0
          ? _buildInvalidUser()
          : (_isLoading && _records.isEmpty && _memberInfo == null)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildProfileAndModeCard(),
                  const SizedBox(height: 10),
                  if (_viewMode == _StatsViewMode.day) _buildDayView(),
                  if (_viewMode == _StatsViewMode.week) _buildWeekView(),
                  if (_viewMode == _StatsViewMode.month) _buildMonthView(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInvalidUser() {
    return Center(
      child: Text(
        '成员信息无效',
        style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildProfileAndModeCard() {
    final displayName = _memberInfo?.name.trim().isNotEmpty == true
        ? _memberInfo!.name
        : '未命名成员';
    final department = _memberInfo?.department.trim().isNotEmpty == true
        ? _memberInfo!.department
        : '暂无部门信息';
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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            backgroundImage: _memberInfo?.avatar.isNotEmpty == true
                ? NetworkImage(_memberInfo!.avatar)
                : null,
            child: _memberInfo?.avatar.isNotEmpty == true
                ? null
                : Text(
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
                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
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

  Widget _buildDayView() {
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
          records: _records,
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

  Widget _buildWeekView() {
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
            detailedStats: _detailedStats,
            fallbackMonthly: _monthlyStats,
          ),
          const SizedBox(height: 8),
          Text(
            '统计截至 ${_statsTimeText(_detailedStats)}',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
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
            detailedStats: _detailedStats,
            fallbackMonthly: _monthlyStats,
          ),
          const SizedBox(height: 10),
          Text(
            '统计截至 ${_statsTimeText(_detailedStats)}',
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
                fontSize: 20,
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
