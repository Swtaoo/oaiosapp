import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/study_page.dart';
import '../../features/home/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/change_info_page.dart';
import '../../features/home/presentation/pages/change_password_page.dart';
import '../../features/home/presentation/pages/personnel_list_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/attendance/presentation/pages/member_detail_page.dart';
import '../../features/approval/presentation/pages/approval_list_page.dart';
import '../../features/approval/presentation/pages/approval_detail_page.dart';
import '../../features/approval/presentation/pages/fund_apply_page.dart';
import '../../features/approval/presentation/pages/salary_detail_page.dart';
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
import '../../features/regulation/presentation/pages/regulation_index_page.dart';
import '../../features/regulation/presentation/pages/regulation_classification_page.dart';
import '../../features/project/presentation/pages/project_list_page.dart';
import '../../features/project/presentation/pages/project_progress_page.dart';
import '../../features/common/presentation/pages/pdf_viewer_page.dart';
import 'auth_guard.dart';
import 'tab_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // 3-Tab Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: 首页
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // Tab 1: 学习空间
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) => const StudyPage(),
              ),
            ],
          ),
          // Tab 2: 我的
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
          final id =
              int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          final type = state.uri.queryParameters['type'] ?? '1';
          return ApprovalDetailPage(
            objectId: id,
            approvalObjectType: type,
          );
        },
      ),
      // 资金申请
      GoRoute(
        path: '/approval/fund-apply',
        builder: (context, state) => const FundApplyPage(),
      ),
      // 工资明细
      GoRoute(
        path: '/approval/salary-detail',
        builder: (context, state) {
          final id =
              int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return SalaryDetailPage(detailId: id);
        },
      ),

      // ========== 个人中心子页面 ==========
      GoRoute(
        path: '/me/changeInfo',
        builder: (context, state) => const ChangeInfoPage(),
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
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '');
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
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '');
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
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '');
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
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '');
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
          final id =
              int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
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
          final realName =
              state.uri.queryParameters['realName'] ?? '';
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
          final title =
              state.uri.queryParameters['title'] ?? '';
          final regulationType =
              int.tryParse(state.uri.queryParameters['regulationType'] ?? '') ??
                  1;
          return RegulationClassificationPage(
            title: title,
            regulationType: regulationType,
          );
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
          final id =
              int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          final name =
              state.uri.queryParameters['name'] ?? '';
          return ProjectProgressPage(projectId: id, projectName: name);
        },
      ),

      // ========== 通用页面 ==========
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final url =
              state.uri.queryParameters['url'] ?? '';
          final title =
              state.uri.queryParameters['title'] ?? 'PDF';
          return PdfViewerPage(url: url, title: title);
        },
      ),
    ],
  );
});
