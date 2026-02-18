import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_models.dart';
import '../../providers/attendance_provider.dart';
import '../widgets/calendar_view.dart';

/// 成员考勤详情页 - 对应 src/pages/attendance/memberDetail.vue
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

class _MemberDetailPageState extends ConsumerState<MemberDetailPage> {
  late int _currentYear;
  late int _currentMonth;
  bool _isLoading = false;
  MemberInfo? _memberInfo;
  MonthlyStats? _stats;
  List<CalendarRecord> _calendarRecords = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = widget.initialYear > 0 ? widget.initialYear : now.year;
    _currentMonth = widget.initialMonth > 0 ? widget.initialMonth : now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.userId <= 0) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(attendanceApiProvider);
      final lastDay = DateTime(_currentYear, _currentMonth + 1, 0).day;
      final endDate =
          '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final res = await api.getMemberDetail(
        userId: widget.userId,
        year: _currentYear,
        month: _currentMonth,
        endDate: endDate,
      );

      if (res.isSuccess && res.data != null) {
        final data = res.data!;
        setState(() {
          _memberInfo = data.memberInfo;
          _stats = data.stats;
          _calendarRecords = data.calendarRecords;
        });
      }
    } catch (e) { debugPrint('[member_detail_page] Error: $e');
      // 错误已在 API 层处理
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleMonthChange(int year, int month) {
    setState(() {
      _currentYear = year;
      _currentMonth = month;
    });
    _loadData();
  }

  /// 将 CalendarRecord 转为 CalendarView 需要的 DailyAttendance 格式
  List<DailyAttendance> get _calendarAsDailyAttendance {
    return _calendarRecords.map((r) {
      return DailyAttendance(
        date: r.date,
        scheduleType: r.scheduleType,
        scheduledClockIn: '',
        scheduledClockOut: '',
        clockInRecord: r.hasClockIn
            ? AttendancePunchRecord(
                id: 0,
                userId: widget.userId,
                punchTime: r.clockInTime ?? '',
                punchLocation: '',
                punchType: 0,
                punchCategory: 0,
              )
            : null,
        clockOutRecord: r.hasClockOut
            ? AttendancePunchRecord(
                id: 0,
                userId: widget.userId,
                punchTime: r.clockOutTime ?? '',
                punchLocation: '',
                punchType: 0,
                punchCategory: 1,
              )
            : null,
        workHours: r.workHours,
        anomalies: r.anomalies,
      );
    }).toList();
  }

  List<_StatGridItem> get _statsGrid {
    if (_stats == null) return [];
    return [
      _StatGridItem(label: '出勤', value: _stats!.actualWorkDays, unit: '天'),
      _StatGridItem(
          label: '迟到', value: _stats!.lateCount, unit: '次', type: 'warning'),
      _StatGridItem(
          label: '早退',
          value: _stats!.earlyLeaveCount,
          unit: '次',
          type: 'warning'),
      _StatGridItem(
          label: '缺卡', value: _stats!.absentCount, unit: '次', type: 'danger'),
      _StatGridItem(
          label: '旷工',
          value: _stats!.absenteeismCount,
          unit: '天',
          type: 'danger'),
      _StatGridItem(label: '外勤', value: _stats!.fieldWorkCount, unit: '次'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('成员考勤详情')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memberInfo == null
              ? _buildEmpty(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 成员信息卡片
                      _buildMemberCard(),
                      const SizedBox(height: 12),
                      // 统计网格
                      if (_stats != null) _buildStatsGrid(),
                      const SizedBox(height: 12),
                      // 日历视图
                      CalendarView(
                        records: _calendarAsDailyAttendance,
                        currentYear: _currentYear,
                        currentMonth: _currentMonth,
                        onMonthChange: _handleMonthChange,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberCard() {
    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _memberInfo!.avatar.isNotEmpty
                ? NetworkImage(_memberInfo!.avatar)
                : null,
            child: _memberInfo!.avatar.isEmpty
                ? Text(
                    _memberInfo!.name.isNotEmpty ? _memberInfo!.name[0] : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _memberInfo!.name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _memberInfo!.department.isNotEmpty
                    ? _memberInfo!.department
                    : '-',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
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
        children: _statsGrid.map((item) {
          Color valueColor = AppColors.textPrimary;
          if (item.type == 'warning') valueColor = AppColors.warning;
          if (item.type == 'danger') valueColor = AppColors.error;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.label}(${item.unit})',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '暂无数据',
            style: TextStyle(
                fontSize: 14, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回上一页'),
          ),
        ],
      ),
    );
  }
}

class _StatGridItem {
  final String label;
  final int value;
  final String unit;
  final String? type;

  const _StatGridItem({
    required this.label,
    required this.value,
    required this.unit,
    this.type,
  });
}
