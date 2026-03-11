import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/workbench_page.dart';
import '../../features/home/presentation/pages/study_page.dart';
import '../../features/home/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/change_info_page.dart';
import '../../features/home/presentation/pages/change_password_page.dart';
import '../../features/home/presentation/pages/personnel_list_page.dart';
import '../../features/home/presentation/pages/quick_actions_edit_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/attendance/presentation/pages/member_detail_page.dart';
import '../../features/approval/presentation/pages/approval_list_page.dart';
import '../../features/approval/presentation/pages/approval_detail_page.dart';
import '../../features/approval/presentation/pages/fund_apply_page.dart';
import '../../features/approval/presentation/pages/reimbursement_apply_page.dart';
import '../../features/approval/presentation/pages/leave_apply_page.dart';
import '../../features/approval/presentation/pages/punch_correct_page.dart';
import '../../features/approval/presentation/pages/trip_apply_page.dart';
import '../../features/approval/presentation/pages/overtime_apply_page.dart';
import '../../features/approval/presentation/pages/confirmation_apply_page.dart';
import '../../features/approval/presentation/pages/salary_adjust_page.dart';
import '../../features/approval/presentation/pages/position_transfer_page.dart';
import '../../features/approval/presentation/pages/resign_apply_page.dart';
import '../../features/approval/presentation/pages/resign_handover_page.dart';
import '../../features/approval/presentation/pages/salary_detail_page.dart';
import '../../features/assistant/presentation/pages/assistant_page.dart';
import '../../features/register/presentation/pages/basic_page.dart';
import '../../features/register/presentation/pages/address_page.dart';
import '../../features/register/presentation/pages/plan_page.dart';
import '../../features/register/presentation/pages/work_page.dart';
import '../../features/register/presentation/pages/work_detail/education_add_page.dart';
import '../../features/register/presentation/pages/work_detail/education_detail_page.dart';
import '../../features/register/presentation/pages/work_detail/training_add_page.dart';
import '../../features/register/presentation/pages/work_detail/training_detail_page.dart';
import '../../features/register/presentation/pages/work_detail/work_add_page.dart';
import '../../features/register/presentation/pages/work_detail/work_detail_page.dart';
import '../../features/register/presentation/pages/work_detail/family_add_page.dart';
import '../../features/register/presentation/pages/work_detail/family_detail_page.dart';
import '../../features/work_report/presentation/pages/work_report_list_page.dart';
import '../../features/work_report/presentation/pages/work_report_publish_page.dart';
import '../../features/work_report/presentation/pages/work_report_detail_page.dart';
import '../../features/contract/presentation/pages/contract_list_page.dart';
import '../../features/contract/presentation/pages/contract_detail_page.dart';
import '../../features/bidding/presentation/pages/bidding_list_page.dart';
import '../../features/regulation/presentation/pages/regulation_index_page.dart';
import '../../features/regulation/presentation/pages/regulation_classification_page.dart';
import '../../features/regulation/presentation/pages/regulation_ai_page.dart';
import '../../features/project/presentation/pages/project_list_page.dart';
import '../../features/project/presentation/pages/project_progress_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/common/presentation/pages/pdf_viewer_page.dart';
import 'auth_guard.dart';
import 'tab_shell.dart';

/// 全局 NavigatorKey - 供通知点击时导航使用
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isLoggedIn ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      // 白名单路由 - 无需登录
      if (AuthGuard.isWhitelisted(state.matchedLocation)) {
        return null;
      }

      // 未登录且不在登录页 -> 跳转登录页
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // 已登录且在登录页 -> 跳转首页
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // 登录
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // 5-Tab Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: 首页
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          // Tab 1: 工作台
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workbench',
                builder: (context, state) => const WorkbenchPage(),
              ),
            ],
          ),
          // Tab 2: AI助手
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (context, state) => const AssistantPage(),
              ),
            ],
          ),
          // Tab 3: 学习空间
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) => const StudyPage(),
              ),
            ],
          ),
          // Tab 4: 我的
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ========== 首页子页面 ==========
      GoRoute(
        path: '/home/quick-actions-edit',
        builder: (context, state) => const QuickActionsEditPage(),
      ),

      // TODO: Phase 3+ - 考勤、审批等子页面路由
      // 考勤页面
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendancePage(),
      ),
      // 成员考勤详情
      GoRoute(
        path: '/attendance/member-detail',
        builder: (context, state) {
          final userId =
              int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
          final year =
              int.tryParse(state.uri.queryParameters['year'] ?? '') ?? 0;
          final month =
              int.tryParse(state.uri.queryParameters['month'] ?? '') ?? 0;
          return MemberDetailPage(
            userId: userId,
            initialYear: year,
            initialMonth: month,
          );
        },
      ),
      // GoRoute(path: '/approval/list', ...),
      // 审批列表
      GoRoute(
        path: '/approval/list',
        builder: (context, state) => const ApprovalListPage(),
      ),
      // 审批详情 (3合1)
      GoRoute(
        path: '/approval/detail',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          final type = state.uri.queryParameters['type'] ?? '1';
          return ApprovalDetailPage(objectId: id, approvalObjectType: type);
        },
      ),
      // 资金申请
      GoRoute(
        path: '/approval/fund-apply',
        builder: (context, state) => const FundApplyPage(),
      ),
      // 报销申请
      GoRoute(
        path: '/approval/reimbursement-apply',
        builder: (context, state) => const ReimbursementApplyPage(),
      ),
      // 请假申请
      GoRoute(
        path: '/approval/leave-apply',
        builder: (context, state) => const LeaveApplyPage(),
      ),
      // 补卡申请
      GoRoute(
        path: '/approval/punch-correct',
        builder: (context, state) => const PunchCorrectPage(),
      ),
      // 出差申请
      GoRoute(
        path: '/approval/trip-apply',
        builder: (context, state) => const TripApplyPage(),
      ),
      // 加班申请
      GoRoute(
        path: '/approval/overtime-apply',
        builder: (context, state) => const OvertimeApplyPage(),
      ),
      // 转正申请
      GoRoute(
        path: '/approval/confirmation-apply',
        builder: (context, state) => const ConfirmationApplyPage(),
      ),
      // 调薪申请
      GoRoute(
        path: '/approval/salary-adjust',
        builder: (context, state) => const SalaryAdjustPage(),
      ),
      // 调岗申请
      GoRoute(
        path: '/approval/position-transfer',
        builder: (context, state) => const PositionTransferPage(),
      ),
      // 离职申请
      GoRoute(
        path: '/approval/resign-apply',
        builder: (context, state) => const ResignApplyPage(),
      ),
      // 离职交接
      GoRoute(
        path: '/approval/resign-handover',
        builder: (context, state) => const ResignHandoverPage(),
      ),
      // 工资明细
      GoRoute(
        path: '/approval/salary-detail',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return SalaryDetailPage(detailId: id);
        },
      ),

      // ========== 个人中心子页面 ==========
      GoRoute(
        path: '/me/changeInfo',
        builder: (context, state) {
          final personnelId = int.tryParse(
            state.uri.queryParameters['personnelId'] ?? '',
          );
          return ChangeInfoPage(personnelId: personnelId);
        },
      ),
      GoRoute(
        path: '/me/changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/me/personnelList',
        builder: (context, state) => const PersonnelListPage(),
      ),

      // ========== 注册/入职登记 ==========
      // Step 1: 基本信息
      GoRoute(
        path: '/register/basic',
        builder: (context, state) => const BasicPage(),
      ),
      // Step 2: 证件信息
      GoRoute(
        path: '/register/address',
        builder: (context, state) => const AddressPage(),
      ),
      // Step 3: 入职规划
      GoRoute(
        path: '/register/plan',
        builder: (context, state) => const PlanPage(),
      ),
      // Step 4: 履历与家庭
      GoRoute(
        path: '/register/work',
        builder: (context, state) => const WorkPage(),
      ),
      // 学习经历 - 添加/编辑
      GoRoute(
        path: '/register/work-detail/education-add',
        builder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '');
          final isEdit = state.uri.queryParameters['mode'] == 'edit';
          return EducationAddPage(index: index, isEdit: isEdit);
        },
      ),
      // 学习经历 - 详情
      GoRoute(
        path: '/register/work-detail/education-detail',
        builder: (context, state) {
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
          return EducationDetailPage(index: index);
        },
      ),
      // 培训经历 - 添加/编辑
      GoRoute(
        path: '/register/work-detail/training-add',
        builder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '');
          final isEdit = state.uri.queryParameters['mode'] == 'edit';
          return TrainingAddPage(index: index, isEdit: isEdit);
        },
      ),
      // 培训经历 - 详情
      GoRoute(
        path: '/register/work-detail/training-detail',
        builder: (context, state) {
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
          return TrainingDetailPage(index: index);
        },
      ),
      // 就职经历 - 添加/编辑
      GoRoute(
        path: '/register/work-detail/work-add',
        builder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '');
          final isEdit = state.uri.queryParameters['mode'] == 'edit';
          return WorkAddPage(index: index, isEdit: isEdit);
        },
      ),
      // 就职经历 - 详情
      GoRoute(
        path: '/register/work-detail/work-detail',
        builder: (context, state) {
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
          return WorkDetailPage(index: index);
        },
      ),
      // 家庭成员 - 添加/编辑
      GoRoute(
        path: '/register/work-detail/family-add',
        builder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '');
          final isEdit = state.uri.queryParameters['mode'] == 'edit';
          return FamilyAddPage(index: index, isEdit: isEdit);
        },
      ),
      // 家庭成员 - 详情
      GoRoute(
        path: '/register/work-detail/family-detail',
        builder: (context, state) {
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
          return FamilyDetailPage(index: index);
        },
      ),

      // ========== 工作汇报 ==========
      GoRoute(
        path: '/work-report',
        builder: (context, state) => const WorkReportListPage(),
      ),
      GoRoute(
        path: '/work-report/publish',
        builder: (context, state) => const WorkReportPublishPage(),
      ),
      GoRoute(
        path: '/work-report/detail',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return WorkReportDetailPage(reportId: id);
        },
      ),

      // ========== 合同管理 ==========
      GoRoute(
        path: '/contract',
        builder: (context, state) => const ContractListPage(),
      ),
      GoRoute(
        path: '/contract/detail',
        builder: (context, state) {
          final userId =
              int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
          final realName = state.uri.queryParameters['realName'] ?? '';
          return ContractDetailPage(userId: userId, realName: realName);
        },
      ),

      // ========== 规章制度 ==========
      GoRoute(
        path: '/regulation',
        builder: (context, state) => const RegulationIndexPage(),
      ),
      GoRoute(
        path: '/regulation/classification',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? '';
          final regulationType =
              int.tryParse(state.uri.queryParameters['regulationType'] ?? '') ??
              1;
          return RegulationClassificationPage(
            title: title,
            regulationType: regulationType,
          );
        },
      ),
      GoRoute(
        path: '/regulation/ai',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'];
          final regulationType = int.tryParse(
            state.uri.queryParameters['regulationType'] ?? '',
          );
          return RegulationAiPage(title: title, regulationType: regulationType);
        },
      ),

      // ========== 项目管理 ==========
      GoRoute(
        path: '/project',
        builder: (context, state) => const ProjectListPage(),
      ),
      GoRoute(
        path: '/project/progress',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          final name = state.uri.queryParameters['name'] ?? '';
          return ProjectProgressPage(projectId: id, projectName: name);
        },
      ),

      // ========== 通用页面 ==========
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'PDF';
          return PdfViewerPage(url: url, title: title);
        },
      ),

      // ========== 投标信息 ==========
      GoRoute(
        path: '/bidding',
        builder: (context, state) => const BiddingListPage(),
      ),

      // ========== 排班管理（仅管理员）==========
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const SchedulePage(),
      ),
    ],
  );
});
