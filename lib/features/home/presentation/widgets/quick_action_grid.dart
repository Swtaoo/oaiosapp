import 'package:flutter/material.dart';

/// 快捷功能网格 - 对应 QuickActionGrid.vue
class QuickActionGrid extends StatelessWidget {
  final void Function(String route)? onActionTap;

  const QuickActionGrid({super.key, this.onActionTap});

  static const _actions = [
    _QuickAction(key: 'approval', label: '文件审批', icon: Icons.task_alt, color: Color(0xFF007AFF), route: '/approval/list'),
    _QuickAction(key: 'project', label: '项目进度', icon: Icons.show_chart, color: Color(0xFFFF9500), route: '/project'),
    _QuickAction(key: 'profile', label: '个人信息', icon: Icons.person_outline, color: Color(0xFF34C759), route: '/register/basic'),
    _QuickAction(key: 'rules', label: '规章制度', icon: Icons.gavel, color: Color(0xFF3B82F6), route: '/regulation'),
    _QuickAction(key: 'contract', label: '合同管理', icon: Icons.description_outlined, color: Color(0xFF0062CC), route: '/contract'),
    _QuickAction(key: 'attendance', label: '考勤打卡', icon: Icons.access_time, color: Color(0xFFFF3B30), route: '/attendance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '常用功能',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _actions.map((action) {
                return GestureDetector(
                  onTap: () => onActionTap?.call(action.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: action.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.label,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}
