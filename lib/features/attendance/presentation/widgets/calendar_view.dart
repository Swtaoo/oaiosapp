import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_models.dart';

/// 日历视图 - 对应 src/pages/attendance/components/CalendarView.vue
class CalendarView extends StatefulWidget {
  final List<DailyAttendance> records;
  final int currentYear;
  final int currentMonth;
  final ValueChanged<String>? onDateSelect;
  final void Function(int year, int month)? onMonthChange;

  const CalendarView({
    super.key,
    required this.records,
    required this.currentYear,
    required this.currentMonth,
    this.onDateSelect,
    this.onMonthChange,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  String _selectedDate = '';
  final _weekDays = ['日', '一', '二', '三', '四', '五', '六'];

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<_CalendarDay> get _calendarDays {
    final year = widget.currentYear;
    final month = widget.currentMonth;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekDay = firstDay.weekday % 7; // Sunday=0
    final totalDays = lastDay.day;
    final today = _todayStr;

    final days = <_CalendarDay>[];

    // 上月填充
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevLastDay = DateTime(prevYear, prevMonth + 1, 0).day;
    for (var i = startWeekDay - 1; i >= 0; i--) {
      final d = prevLastDay - i;
      days.add(_CalendarDay(
        date: '$prevYear-${prevMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        day: d,
        isCurrentMonth: false,
        isToday: false,
        status: 'none',
        hasClockIn: false,
        hasClockOut: false,
      ));
    }

    // 当月
    for (var d = 1; d <= totalDays; d++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final record = widget.records.where((r) => r.date == dateStr).firstOrNull;
      var status = 'none';
      if (record != null) {
        if (record.scheduleType == 'rest' ||
            record.scheduleType == 'holiday') {
          status = 'rest';
        } else if (record.anomalies.isNotEmpty) {
          if (record.anomalies.contains('迟到')) {
            status = 'late';
          } else if (record.anomalies.contains('早退')) {
            status = 'early';
          } else if (record.anomalies.contains('缺卡')) {
            status = 'absent';
          } else {
            status = 'normal';
          }
        } else if (record.clockInRecord != null ||
            record.clockOutRecord != null) {
          status = 'normal';
        }
      }

      days.add(_CalendarDay(
        date: dateStr,
        day: d,
        isCurrentMonth: true,
        isToday: dateStr == today,
        status: status,
        hasClockIn: record?.clockInRecord != null,
        hasClockOut: record?.clockOutRecord != null,
      ));
    }

    // 下月填充
    final remaining = 42 - days.length;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    for (var d = 1; d <= remaining; d++) {
      days.add(_CalendarDay(
        date: '$nextYear-${nextMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        day: d,
        isCurrentMonth: false,
        isToday: false,
        status: 'none',
        hasClockIn: false,
        hasClockOut: false,
      ));
    }

    return days;
  }

  void _prevMonth() {
    var y = widget.currentYear;
    var m = widget.currentMonth - 1;
    if (m < 1) {
      m = 12;
      y--;
    }
    widget.onMonthChange?.call(y, m);
  }

  void _nextMonth() {
    var y = widget.currentYear;
    var m = widget.currentMonth + 1;
    if (m > 12) {
      m = 1;
      y++;
    }
    widget.onMonthChange?.call(y, m);
  }

  void _selectDate(_CalendarDay day) {
    if (!day.isCurrentMonth) return;
    setState(() => _selectedDate = day.date);
    widget.onDateSelect?.call(day.date);
  }

  Color _getDayColor(_CalendarDay day) {
    if (_selectedDate == day.date) return Colors.white;
    if (!day.isCurrentMonth) return AppColors.textQuaternary;
    switch (day.status) {
      case 'normal':
        return AppColors.success;
      case 'late':
      case 'early':
        return AppColors.warning;
      case 'absent':
        return AppColors.error;
      default:
        if (day.isToday) return AppColors.primary;
        return AppColors.textPrimary;
    }
  }

  Color? _getDayBgColor(_CalendarDay day) {
    if (_selectedDate == day.date) return AppColors.primary;
    if (day.isToday) return AppColors.primary.withValues(alpha: 0.1);
    if (day.status == 'rest') return const Color(0xFFF9FAFB);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays;

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份导航
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.chevron_left,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${widget.currentYear}年${widget.currentMonth}月',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 星期头
          Row(
            children: _weekDays
                .map((w) => Expanded(
                      child: Text(
                        w,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // 日历网格
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: days.map((day) {
              final bgColor = _getDayBgColor(day);
              return GestureDetector(
                onTap: () => _selectDate(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: day.isToday ||
                                  _selectedDate == day.date
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _getDayColor(day),
                        ),
                      ),
                      if (day.isCurrentMonth &&
                          day.status != 'none' &&
                          day.status != 'rest')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (day.hasClockIn)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2, right: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            if (day.hasClockOut)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // 底部图例
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Divider(
                height: 1, color: AppColors.separatorNonOpaque),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(AppColors.success, '正常'),
                const SizedBox(width: 16),
                _legendItem(AppColors.warning, '迟到/早退'),
                const SizedBox(width: 16),
                _legendItem(AppColors.error, '缺卡'),
                const SizedBox(width: 16),
                _legendItem(AppColors.neutral300, '休息'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _CalendarDay {
  final String date;
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final String status;
  final bool hasClockIn;
  final bool hasClockOut;

  const _CalendarDay({
    required this.date,
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.status,
    required this.hasClockIn,
    required this.hasClockOut,
  });
}
