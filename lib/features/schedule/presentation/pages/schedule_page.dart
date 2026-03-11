import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/schedule_models.dart';
import '../../providers/schedule_provider.dart';

/// 排班管理页面 - 仅管理员可用
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  static const _weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

  static const _avatarColors = [
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFFFF3B30),
    Color(0xFF00C7BE),
    Color(0xFF5856D6),
  ];

  Color _avatarColor(int idx) => _avatarColors[idx % _avatarColors.length];

  int _userIndex(List<ScheduleUser> users, ScheduleUser? user) {
    if (user == null) return 0;
    final idx = users.indexWhere((u) => u.userId == user.userId);
    return idx < 0 ? 0 : idx;
  }

  /// 计算指定月份的周末日期集合（用于批量排班默认值）
  Set<String> _weekendDatesOf(int year, int month) {
    final result = <String>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(year, month, d);
      if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
        result.add(
            '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}');
      }
    }
    return result;
  }

  void _showBatchScheduler(BuildContext context, ScheduleState store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        // 本地状态：年月 + 当月休息日集合
        var batchYear = store.year;
        var batchMonth = store.month;
        Set<String> batchRest = _weekendDatesOf(batchYear, batchMonth);
        final today = _todayStr;

        return StatefulBuilder(
          builder: (ctx, setS) {
            final calDays = _buildCalendar(batchYear, batchMonth);
            final screenH = MediaQuery.of(context).size.height;
            final bottomPad = MediaQuery.of(context).padding.bottom;
            final totalDays = DateTime(batchYear, batchMonth + 1, 0).day;
            final restCount = batchRest.length;
            final workCount = totalDays - restCount;

            void prevMonth() => setS(() {
                  if (batchMonth == 1) {
                    batchYear--;
                    batchMonth = 12;
                  } else {
                    batchMonth--;
                  }
                  batchRest = _weekendDatesOf(batchYear, batchMonth);
                });

            void nextMonth() => setS(() {
                  if (batchMonth == 12) {
                    batchYear++;
                    batchMonth = 1;
                  } else {
                    batchMonth++;
                  }
                  batchRest = _weekendDatesOf(batchYear, batchMonth);
                });

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenH * 0.90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽条
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题 + 统计徽章
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '全体统一排班',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '将覆盖全体 ${store.users.length} 名员工',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        _BatchBadge(
                            label: '出勤 $workCount 天',
                            color: AppColors.primary),
                        const SizedBox(width: 6),
                        _BatchBadge(
                            label: '休息 $restCount 天',
                            color: AppColors.error),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.neutral100),
                  // 月份导航
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        _NavBtn(icon: Icons.chevron_left, onTap: prevMonth),
                        Expanded(
                          child: Text(
                            '$batchYear年 $batchMonth月',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _NavBtn(icon: Icons.chevron_right, onTap: nextMonth),
                      ],
                    ),
                  ),
                  // 星期头
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _weekLabels
                          .map((w) => Expanded(
                                child: Text(
                                  w,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: (w == '日' || w == '六')
                                        ? AppColors.error.withValues(alpha: 0.6)
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 日历网格
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: LayoutBuilder(builder: (lCtx, constraints) {
                        final cellW = constraints.maxWidth / 7;
                        const cellH = 52.0;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: cellW / cellH,
                            mainAxisSpacing: 3,
                          ),
                          itemCount: calDays.length,
                          itemBuilder: (_, i) {
                            final day = calDays[i];
                            if (!day.isCurrentMonth) {
                              return _GhostCell(day: day.day);
                            }
                            final isRest = batchRest.contains(day.date);
                            final isToday = day.date == today;
                            final isWeekend = (i % 7 == 0) || (i % 7 == 6);
                            return _DayCell(
                              day: day.day,
                              isRest: isRest,
                              isToday: isToday,
                              isWeekend: isWeekend,
                              isSaving: false,
                              onTap: () => setS(() {
                                if (isRest) {
                                  batchRest.remove(day.date);
                                } else {
                                  batchRest.add(day.date);
                                }
                              }),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                  Divider(height: 0.5, color: AppColors.neutral100),
                  // 图例 + 快捷按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _LegendChip(
                            color: AppColors.primary,
                            bgColor: AppColors.primary50,
                            label: '标准班'),
                        const SizedBox(width: 12),
                        _LegendChip(
                            color: AppColors.error,
                            bgColor: const Color(0xFFFFF1F0),
                            label: '休息'),
                        const Spacer(),
                        _QuickChip(
                          label: '仅周末',
                          onTap: () => setS(() {
                            batchRest = _weekendDatesOf(batchYear, batchMonth);
                          }),
                        ),
                        const SizedBox(width: 6),
                        _QuickChip(
                          label: '全部上班',
                          onTap: () => setS(() => batchRest = {}),
                        ),
                      ],
                    ),
                  ),
                  // 确认按钮
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(scheduleProvider.notifier).setBatchMonth(
                                batchYear,
                                batchMonth,
                                Set.from(batchRest),
                              );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          '应用到全体 ${store.users.length} 名员工',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserPicker(BuildContext context, ScheduleState store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final allUsers = store.users;
            final filtered = query.isEmpty
                ? allUsers
                : allUsers
                    .where((u) =>
                        u.name.contains(query) ||
                        u.department.contains(query))
                    .toList();

            final screenH = MediaQuery.of(context).size.height;
            final keyboardH = MediaQuery.of(ctx).viewInsets.bottom;
            final bottomPad = MediaQuery.of(context).padding.bottom;

            return Padding(
              // 键盘弹出时整体上移
              padding: EdgeInsets.only(bottom: keyboardH),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenH * 0.72),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 拖拽条
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 标题
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Text(
                        '选择排班员工',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // 搜索框
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: TextField(
                        autofocus: false,
                        onChanged: (v) =>
                            setModalState(() => query = v.trim()),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '搜索姓名或部门',
                          hintStyle: TextStyle(
                              fontSize: 14, color: AppColors.textTertiary),
                          prefixIcon: Icon(Icons.search,
                              size: 20, color: AppColors.textTertiary),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: AppColors.backgroundSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 0.5, color: AppColors.neutral100),
                    // 员工列表
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 36, color: AppColors.neutral300),
                                  const SizedBox(height: 8),
                                  Text('无匹配员工',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textTertiary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(
                                  height: 0.5,
                                  indent: 56,
                                  color: AppColors.neutral100),
                              itemBuilder: (_, idx) {
                                final user = filtered[idx];
                                final isSelected =
                                    store.selectedUser?.userId == user.userId;
                                // 颜色按原始列表索引，切换筛选时颜色不变
                                final origIdx = allUsers
                                    .indexWhere((u) => u.userId == user.userId);
                                final color = _avatarColor(origIdx);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                                  leading: _AvatarCircle(
                                      name: user.name, color: color, size: 36),
                                  title: Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: user.department.isNotEmpty
                                      ? Text(user.department,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textTertiary))
                                      : null,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: AppColors.primary, size: 20)
                                      : null,
                                  onTap: () {
                                    ref
                                        .read(scheduleProvider.notifier)
                                        .selectUser(user);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                    SizedBox(height: bottomPad + 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(scheduleProvider.notifier).init());
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  void _prevMonth() {
    final s = ref.read(scheduleProvider);
    var y = s.year;
    var m = s.month - 1;
    if (m < 1) { m = 12; y--; }
    ref.read(scheduleProvider.notifier).changeMonth(y, m);
  }

  void _nextMonth() {
    final s = ref.read(scheduleProvider);
    var y = s.year;
    var m = s.month + 1;
    if (m > 12) { m = 1; y++; }
    ref.read(scheduleProvider.notifier).changeMonth(y, m);
  }

  List<_CalDay> _buildCalendar(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekDay = firstDay.weekday % 7;
    final days = <_CalDay>[];

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevLastDay = DateTime(prevYear, prevMonth + 1, 0).day;
    for (var i = startWeekDay - 1; i >= 0; i--) {
      days.add(_CalDay(date: '', day: prevLastDay - i, isCurrentMonth: false));
    }
    for (var d = 1; d <= lastDay.day; d++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      days.add(_CalDay(date: dateStr, day: d, isCurrentMonth: true));
    }
    final remaining = 42 - days.length;
    for (var d = 1; d <= remaining; d++) {
      days.add(_CalDay(date: '', day: d, isCurrentMonth: false));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('排班管理')),
        body: const Center(child: Text('仅管理员可使用此功能')),
      );
    }

    final store = ref.watch(scheduleProvider);

    ref.listen(scheduleProvider.select((s) => s.error), (_, err) {
      if (err != null && err.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text(
          '排班管理',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: store.isBatchSaving
                ? null
                : () => _showBatchScheduler(context, store),
            child: store.isBatchSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    '全体排班',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: AppColors.separatorNonOpaque),
        ),
      ),
      body: store.isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : store.users.isEmpty
              ? _buildEmpty()
              : _buildBody(store),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 52, color: AppColors.neutral300),
          const SizedBox(height: 12),
          Text('暂无在职人员',
              style:
                  TextStyle(fontSize: 15, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildBody(ScheduleState store) {
    final calDays = _buildCalendar(store.year, store.month);
    final today = _todayStr;
    final restCount = store.restDates.length;
    final totalDays = DateTime(store.year, store.month + 1, 0).day;
    final workCount = totalDays - restCount;

    return Column(
      children: [
        // ── 人员选择器 ──
        _buildUserSelector(store),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Column(
              children: [
                // ── 日历卡片 ──
                _buildCalendarCard(store, calDays, today),

                const SizedBox(height: 12),

                // ── 统计汇总 ──
                _buildSummaryRow(workCount, restCount),

                const SizedBox(height: 10),

                // ── 操作提示 ──
                Text(
                  '点击日期可切换班次 / 休息',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 人员选择器（紧凑单行）────────────────────
  Widget _buildUserSelector(ScheduleState store) {
    final user = store.selectedUser;
    final idx = _userIndex(store.users, user);
    final color = _avatarColor(idx);

    return GestureDetector(
      onTap: () => _showUserPicker(context, store),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (user != null)
              _AvatarCircle(name: user.name, color: color, size: 34)
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neutral100,
                ),
                child: Icon(Icons.person_outline,
                    size: 18, color: AppColors.textTertiary),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '排班对象',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user?.name ?? '请选择员工',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: user != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '切换',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── 日历卡片 ──────────────────────────────
  Widget _buildCalendarCard(
      ScheduleState store, List<_CalDay> calDays, String today) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份导航
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _NavBtn(icon: Icons.chevron_left, onTap: _prevMonth),
                Expanded(
                  child: Text(
                    '${store.year}年 ${store.month}月',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                _NavBtn(icon: Icons.chevron_right, onTap: _nextMonth),
              ],
            ),
          ),

          // 星期头
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekLabels
                  .map((w) => Expanded(
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: (w == '日' || w == '六')
                                ? AppColors.error.withValues(alpha: 0.6)
                                : AppColors.textTertiary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          Divider(height: 0.5, color: AppColors.neutral100),
          const SizedBox(height: 6),

          // 日历网格
          if (store.isLoadingSchedule)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 72),
              child: CircularProgressIndicator(),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              final cellW = (constraints.maxWidth - 16) / 7;
              const cellH = 64.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: cellW / cellH,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 0,
                  ),
                  itemCount: calDays.length,
                  itemBuilder: (_, i) {
                    final day = calDays[i];
                    if (!day.isCurrentMonth) {
                      return _GhostCell(day: day.day);
                    }
                    final isRest = store.restDates.contains(day.date);
                    final isSaving = store.savingDates.contains(day.date);
                    final isToday = day.date == today;
                    // 判断周末（格子索引 % 7 == 0=日, 6=六）
                    final isWeekend = (i % 7 == 0) || (i % 7 == 6);
                    return _DayCell(
                      day: day.day,
                      isRest: isRest,
                      isToday: isToday,
                      isWeekend: isWeekend,
                      isSaving: isSaving,
                      onTap: () => ref
                          .read(scheduleProvider.notifier)
                          .toggleDay(day.date),
                    );
                  },
                ),
              );
            }),

          const SizedBox(height: 8),
          Divider(height: 0.5, color: AppColors.neutral100),

          // 图例
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendChip(
                  color: AppColors.primary,
                  bgColor: AppColors.primary50,
                  label: '标准班',
                ),
                const SizedBox(width: 16),
                _LegendChip(
                  color: AppColors.error,
                  bgColor: const Color(0xFFFFF1F0),
                  label: '休息',
                ),
                const SizedBox(width: 16),
                _LegendChip(
                  color: AppColors.textTertiary,
                  bgColor: AppColors.neutral100,
                  label: '非本月',
                  dot: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 统计行 ───────────────────────────────
  Widget _buildSummaryRow(int workCount, int restCount) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.work_outline,
            iconColor: AppColors.primary,
            bgColor: AppColors.primary50,
            label: '出勤',
            value: '$workCount 天',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.weekend_outlined,
            iconColor: AppColors.error,
            bgColor: const Color(0xFFFFF1F0),
            label: '休息',
            value: '$restCount 天',
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// 子 Widget
// ══════════════════════════════════════════════

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isRest;
  final bool isToday;
  final bool isWeekend;
  final bool isSaving;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isRest,
    required this.isToday,
    required this.isWeekend,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 颜色语义
    const restBg = Color(0xFFFFF1F0);
    const restLabel = AppColors.error;
    final workBg = isWeekend
        ? const Color(0xFFFFF8F0)
        : const Color(0xFFF0F6FF);
    final workLabel =
        isWeekend ? AppColors.warning : AppColors.primary;

    final bg = isRest ? restBg : workBg;
    final labelColor = isRest ? restLabel : workLabel;
    final labelText = isRest ? '休' : '班';

    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 日期数字
            Text(
              '$day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? AppColors.primary
                    : isRest
                        ? AppColors.error.withValues(alpha: 0.85)
                        : isWeekend
                            ? AppColors.warning
                            : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            // 班次标签 or loading
            if (isSaving)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: labelColor,
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GhostCell extends StatelessWidget {
  final int day;
  const _GhostCell({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$day',
        style: TextStyle(fontSize: 13, color: AppColors.textQuaternary),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final String label;
  final bool dot;

  const _LegendChip({
    required this.color,
    required this.bgColor,
    required this.label,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot ? 8 : 8,
          height: 8,
          decoration: BoxDecoration(
            shape: dot ? BoxShape.circle : BoxShape.rectangle,
            color: dot ? color : Colors.transparent,
            borderRadius: dot ? null : BorderRadius.circular(2),
            border: dot ? null : Border.all(color: color, width: 1),
          ),
          child: dot
              ? null
              : Icon(Icons.remove, size: 8, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 内部数据
// ══════════════════════════════════════════════
class _CalDay {
  final String date;
  final int day;
  final bool isCurrentMonth;

  const _CalDay({
    required this.date,
    required this.day,
    required this.isCurrentMonth,
  });
}

// ══════════════════════════════════════════════
// 头像圆（姓名首字）
// ══════════════════════════════════════════════
class _AvatarCircle extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _AvatarCircle({
    required this.name,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 批量排班统计徽章
// ══════════════════════════════════════════════
class _BatchBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _BatchBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 快捷操作小按钮
// ══════════════════════════════════════════════
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
    );
  }
}
