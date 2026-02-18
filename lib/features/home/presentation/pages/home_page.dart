import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/attendance_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/pending_summary.dart';
import '../widgets/notification_list.dart';
import '../widgets/work_report_card.dart';

/// 首页 - 对应 src/pages/index/index.vue
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(currentUserProvider);
    final nickname = userInfo?.displayName ?? '用户';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Phase 3/4 - 刷新考勤和审批数据
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部 Header
              HomeHeader(
                nickname: nickname,
                unreadCount: 0, // TODO: Phase 9 - 绑定通知 store
                onNotificationTap: () => context.push('/project'),
                onAvatarTap: () {
                  // 切换到 "我的" tab
                  StatefulNavigationShell.maybeOf(context)?.goBranch(2);
                },
              ),
              // 考勤卡片
              AttendanceCard(
                onTap: () => context.push('/attendance'),
              ),
              const SizedBox(height: 16),
              // 快捷功能
              QuickActionGrid(
                onActionTap: (route) => context.push(route),
              ),
              const SizedBox(height: 16),
              // 待办摘要
              PendingSummary(
                pendingCount: 0, // TODO: Phase 4 - 绑定审批 store
                unreadCount: 0,
                onApprovalTap: () => context.push('/approval/list'),
                onMessageTap: () => context.push('/project'),
              ),
              const SizedBox(height: 16),
              // 工作汇报
              const WorkReportCard(),
              const SizedBox(height: 16),
              // 通知列表
              NotificationList(
                onViewAll: () => context.push('/project'),
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
