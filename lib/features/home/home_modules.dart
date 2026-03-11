import 'package:flutter/material.dart';

/// 首页/工作台通用的应用模块定义
///
/// - `key`: 用于后端/本地持久化常用功能配置
/// - `route`: 对应 GoRouter 路由；`profile` 为动态路由（管理员/普通员工不同）
class HomeModule {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  /// 是否仅管理员可见（在快捷宫格和编辑页中对普通员工隐藏）
  final bool adminOnly;

  const HomeModule({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.adminOnly = false,
  });
}

/// 全部应用
const List<HomeModule> kAllHomeModules = [
  HomeModule(
    key: 'approval',
    label: '文件审批',
    icon: Icons.task_alt,
    color: Color(0xFF007AFF),
    route: '/approval/list',
  ),
  HomeModule(
    key: 'project',
    label: '项目进度',
    icon: Icons.show_chart,
    color: Color(0xFFFF9500),
    route: '/project',
  ),
  HomeModule(
    key: 'profile',
    label: '人员信息',
    icon: Icons.person_outline,
    color: Color(0xFF34C759),
    route: '',
  ),
  HomeModule(
    key: 'rules',
    label: '规章制度',
    icon: Icons.gavel,
    color: Color(0xFF3B82F6),
    route: '/regulation',
  ),
  HomeModule(
    key: 'contract',
    label: '合同管理',
    icon: Icons.description_outlined,
    color: Color(0xFF0062CC),
    route: '/contract',
  ),
  HomeModule(
    key: 'attendance',
    label: '考勤打卡',
    icon: Icons.access_time,
    color: Color(0xFFFF3B30),
    route: '/attendance',
  ),
  HomeModule(
    key: 'fundApply',
    label: '资金申请',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF0A84FF),
    route: '/approval/fund-apply',
  ),
  HomeModule(
    key: 'reimbursementApply',
    label: '报销申请',
    icon: Icons.receipt_long,
    color: Color(0xFFFF375F),
    route: '/approval/reimbursement-apply',
  ),
  HomeModule(
    key: 'leave',
    label: '请假申请',
    icon: Icons.event_busy,
    color: Color(0xFFAF52DE),
    route: '/approval/leave-apply',
  ),
  HomeModule(
    key: 'punchCorrect',
    label: '补卡申请',
    icon: Icons.edit_calendar,
    color: Color(0xFF5AC8FA),
    route: '/approval/punch-correct',
  ),
  HomeModule(
    key: 'trip',
    label: '出差申请',
    icon: Icons.flight_takeoff,
    color: Color(0xFFFF6B35),
    route: '/approval/trip-apply',
  ),
  HomeModule(
    key: 'overtime',
    label: '加班申请',
    icon: Icons.more_time,
    color: Color(0xFF30D158),
    route: '/approval/overtime-apply',
  ),
  HomeModule(
    key: 'confirmation',
    label: '转正申请',
    icon: Icons.verified_user,
    color: Color(0xFF00C7BE),
    route: '/approval/confirmation-apply',
  ),
  HomeModule(
    key: 'salaryAdjust',
    label: '调薪申请',
    icon: Icons.trending_up,
    color: Color(0xFFFF9500),
    route: '/approval/salary-adjust',
  ),
  HomeModule(
    key: 'positionTransfer',
    label: '调岗申请',
    icon: Icons.swap_horiz,
    color: Color(0xFF64D2FF),
    route: '/approval/position-transfer',
  ),
  HomeModule(
    key: 'resign',
    label: '离职申请',
    icon: Icons.exit_to_app,
    color: Color(0xFFFF453A),
    route: '/approval/resign-apply',
  ),
  HomeModule(
    key: 'resignHandover',
    label: '离职交接',
    icon: Icons.assignment_turned_in,
    color: Color(0xFF8E8E93),
    route: '/approval/resign-handover',
  ),
  HomeModule(
    key: 'workReport',
    label: '工作汇报',
    icon: Icons.description_outlined,
    color: Color(0xFF5856D6),
    route: '/work-report',
  ),
  HomeModule(
    key: 'bidding',
    label: '投标信息',
    icon: Icons.assignment_outlined,
    color: Color(0xFFE67E22),
    route: '/bidding',
  ),
  HomeModule(
    key: 'schedule',
    label: '排班管理',
    icon: Icons.calendar_month,
    color: Color(0xFF34AADC),
    route: '/schedule',
    adminOnly: true,
  ),
];

/// 首页「常用功能」默认配置（保持旧版默认顺序）
const List<String> kDefaultQuickActionKeys = [
  'approval',
  'project',
  'profile',
  'rules',
  'contract',
  'attendance',
  'leave',
  'punchCorrect',
  'trip',
  'overtime',
];
