import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/punch_tab.dart';
import '../widgets/stats_tab.dart';
import '../widgets/team_stats_tab.dart';

/// 考勤页面 - 对应 src/pages/attendance/index.vue
/// 内含 3 个 tab: 打卡 / 统计 / 团队(仅管理员)
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final tabs = [
      const _TabConfig(key: 'punch', label: '打卡', icon: Icons.location_on),
      const _TabConfig(key: 'stats', label: '统计', icon: Icons.bar_chart),
      if (isAdmin)
        const _TabConfig(key: 'team', label: '团队', icon: Icons.group),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('考勤'),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                const PunchTab(),
                const StatsTab(),
                if (isAdmin) const TeamStatsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isActive = _currentTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = index),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 24,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String key;
  final String label;
  final IconData icon;

  const _TabConfig({
    required this.key,
    required this.label,
    required this.icon,
  });
}
