import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/notification/notification_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../approval/providers/approval_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/attendance_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/pending_summary.dart';
import '../widgets/notification_list.dart';
import '../widgets/work_report_card.dart';

/// 首页 - 对应 src/pages/index/index.vue
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    ref.read(attendanceProvider.notifier).init();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(attendanceProvider.notifier).fetchTodayData(),
      // 下拉刷新时同步刷新待我审批数量
      ref.refresh(myPendingCountProvider.future).catchError((_) => 0),
    ]);
  }

  /// 从 unreadMap 构建通知列表（最多5条，按时间降序）
  List<NotificationItem> _buildNotifications(NotificationState notifState) {
    final entries = notifState.unreadMap.entries
        .where((e) => e.value.count > 0)
        .toList();

    // 按最后消息时间降序排列
    entries.sort((a, b) {
      final ta = a.value.lastTimestamp ?? 0;
      final tb = b.value.lastTimestamp ?? 0;
      return tb.compareTo(ta);
    });

    return entries.take(5).map((entry) {
      final info = entry.value;
      return NotificationItem(
        projectId: entry.key,
        projectName: info.projectName ?? notifState.getProjectName(entry.key),
        content: info.lastContent ?? '[消息]',
        senderName: info.lastSenderName ?? '',
        timestamp: info.lastTimestamp ?? 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(currentUserProvider);
    final nickname = userInfo?.displayName ?? '用户';
    final attendance = ref.watch(attendanceProvider);
    final notifState = ref.watch(notificationServiceProvider);
    final totalUnread = notifState.totalUnread;
    final myPendingCountAsync = ref.watch(myPendingCountProvider);
    final myPendingCount = myPendingCountAsync.valueOrNull ?? 0;
    final notifications = _buildNotifications(notifState);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部 Header
              HomeHeader(
                nickname: nickname,
                unreadCount: totalUnread,
                onNotificationTap: () => context.push('/project'),
                onAvatarTap: () {
                  // 切换到 "我的" tab
                  StatefulNavigationShell.maybeOf(context)?.goBranch(4);
                },
              ),
              // 考勤卡片
              AttendanceCard(
                isLoading: attendance.isLoading,
                hasClockedIn: attendance.hasClockedIn,
                hasClockedOut: attendance.hasClockedOut,
                clockInTime: attendance.clockInTime,
                clockOutTime: attendance.clockOutTime,
                scheduledClockIn: attendance.scheduledClockIn,
                scheduledClockOut: attendance.scheduledClockOut,
                onTap: () => context.push('/attendance'),
              ),
              const SizedBox(height: 16),
              // 快捷功能
              QuickActionGrid(
                onActionTap: (route) => context.push(route),
                onEditTap: () => context.push('/home/quick-actions-edit'),
              ),
              const SizedBox(height: 16),
              // 待办摘要
              PendingSummary(
                pendingCount: myPendingCount,
                unreadCount: totalUnread,
                onApprovalTap: () {
                  // 首页待办默认跳转到「待我审批」
                  ref
                      .read(approvalListProvider.notifier)
                      .setFilter('myPending');
                  context.push('/approval/list');
                },
                onMessageTap: () => context.push('/project'),
              ),
              const SizedBox(height: 16),
              // 工作汇报
              const WorkReportCard(),
              const SizedBox(height: 16),
              // 通知列表
              NotificationList(
                notifications: notifications,
                onViewAll: () => context.push('/project'),
                onItemTap: (item) {
                  context.push(
                    '/project/progress?id=${item.projectId}&name=${Uri.encodeComponent(item.projectName)}',
                  );
                },
              ),
              // 底部安全区间距
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
