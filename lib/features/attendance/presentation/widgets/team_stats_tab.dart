import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_models.dart';
import '../../providers/attendance_provider.dart';

/// 团队统计标签页 - 对应 src/pages/attendance/components/TeamStatsTab.vue
class TeamStatsTab extends ConsumerStatefulWidget {
  const TeamStatsTab({super.key});

  @override
  ConsumerState<TeamStatsTab> createState() => _TeamStatsTabState();
}

class _TeamStatsTabState extends ConsumerState<TeamStatsTab> {
  static const _categories = [
    _SortCategory(key: 'averageWorkHours', label: '平均工时'),
    _SortCategory(key: 'lateCount', label: '迟到'),
    _SortCategory(key: 'earlyLeaveCount', label: '早退'),
    _SortCategory(key: 'absentCount', label: '缺卡'),
    _SortCategory(key: 'absenteeismCount', label: '旷工'),
    _SortCategory(key: 'fieldWorkCount', label: '外勤'),
  ];

  String _currentCategory = 'averageWorkHours';
  late int _currentYear;
  late int _currentMonthNum;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonthNum = now.month;
    Future.microtask(() => _loadData());
  }

  String _getEndDate(int year, int month) {
    final now = DateTime.now();
    final lastDay = DateTime(year, month + 1, 0).day;
    final monthEnd =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    if (year > now.year ||
        (year == now.year && month >= now.month)) {
      return DateFormat('yyyy-MM-dd').format(now);
    }
    return monthEnd;
  }

  String get _currentMonth =>
      '$_currentYear.${_currentMonthNum.toString().padLeft(2, '0')}';

  String get _categoryDisplayValue {
    final store = ref.read(attendanceProvider);
    final members = store.teamStats?.members ?? [];
    final cat = _categories.firstWhere((c) => c.key == _currentCategory);

    if (_currentCategory == 'averageWorkHours') {
      final avg =
          store.teamStats?.teamAverageHours.toStringAsFixed(1) ?? '0';
      return '以下人员平均工时 $avg小时';
    }
    final total = members.fold<num>(
        0, (sum, m) => sum + m.getValueByKey(_currentCategory));
    final unit = _currentCategory == 'absenteeismCount' ? '天' : '次';
    return '以下人员${cat.label}共 $total$unit';
  }

  String get _categoryDescription {
    if (_currentCategory == 'averageWorkHours') {
      return '平均工时=员工打卡工时总和 / 员工打卡天数总和';
    }
    return '';
  }

  List<TeamMemberStats> get _sortedMembers {
    final members =
        List<TeamMemberStats>.from(ref.read(attendanceProvider).teamStats?.members ?? []);
    members.sort((a, b) => b
        .getValueByKey(_currentCategory)
        .compareTo(a.getValueByKey(_currentCategory)));
    return members;
  }

  String _getDisplayValue(TeamMemberStats member) {
    final val = member.getValueByKey(_currentCategory);
    if (_currentCategory == 'averageWorkHours') return '$val小时';
    if (_currentCategory == 'absenteeismCount') return '$val天';
    return '$val次';
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonthNum == 1) {
        _currentMonthNum = 12;
        _currentYear--;
      } else {
        _currentMonthNum--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final isCurrentMonth =
        _currentYear == now.year && _currentMonthNum == now.month;
    if (isCurrentMonth) return;

    setState(() {
      if (_currentMonthNum == 12) {
        _currentMonthNum = 1;
        _currentYear++;
      } else {
        _currentMonthNum++;
      }
    });
    _loadData();
  }

  void _loadData() {
    final endDate = _getEndDate(_currentYear, _currentMonthNum);
    ref.read(attendanceProvider.notifier).fetchTeamStats(
          _currentYear,
          _currentMonthNum,
          endDate: endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(attendanceProvider);
    final sorted = _sortedMembers;

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: CustomScrollView(
        slivers: [
          // 分类标签栏
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _categories.map((cat) {
                    final isActive = _currentCategory == cat.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _currentCategory = cat.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // 月份选择 + 统计说明
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _prevMonth,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.chevron_left,
                              size: 20, color: AppColors.textTertiary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _currentMonth,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: _nextMonth,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.chevron_right,
                              size: 20, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _categoryDisplayValue,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_categoryDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _categoryDescription,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 加载态
          if (store.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          // 空状态
          else if (sorted.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.group, size: 48, color: AppColors.neutral300),
                    const SizedBox(height: 8),
                    Text(
                      '暂无团队数据',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          // 成员列表
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = sorted[index];
                  final isLast = index == sorted.length - 1;
                  return GestureDetector(
                    onTap: () => context.push(
                      '/attendance/member-detail?userId=${member.userId}&year=$_currentYear&month=$_currentMonthNum',
                    ),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                // 头像
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: member.avatar.isNotEmpty
                                      ? NetworkImage(member.avatar)
                                      : null,
                                  child: member.avatar.isEmpty
                                      ? Text(
                                          member.name.isNotEmpty
                                              ? member.name[0]
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                // 姓名 + 部门
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member.department.isNotEmpty
                                            ? member.department
                                            : '-',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textTertiary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // 数值
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _getDisplayValue(member),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '出勤${member.actualWorkDays}天',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right,
                                    size: 16, color: AppColors.textQuaternary),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: AppColors.separatorNonOpaque,
                              indent: 12,
                              endIndent: 12,
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _SortCategory {
  final String key;
  final String label;

  const _SortCategory({required this.key, required this.label});
}
