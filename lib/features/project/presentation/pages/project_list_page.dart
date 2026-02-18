// 项目列表页 - 企微会话列表风格
// Phase 4: 按 lastTimestamp 排序 + 未读徽章 + 最后消息摘要

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/notification/notification_service.dart';
import '../../data/models/project_models.dart';
import '../../providers/project_providers.dart';
import '../widgets/conversation_list_item.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  List<ProjectInfoVo> _projects = [];
  bool _isLoading = true;

  /// 项目 id -> 项目经理姓名
  final Map<int, String> _managerNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(projectApiProvider);
      final res = await api.getProjectList();
      if (res.isSuccess) {
        final projects =
            (res.rows ?? []).where((p) => p.delFlag != 2).toList();
        setState(() => _projects = projects);

        // 缓存项目名称到通知服务
        final notifier = ref.read(notificationServiceProvider.notifier);
        for (final p in projects) {
          if (p.id != null && p.projectName != null) {
            notifier.cacheProjectName(p.id!, p.projectName!);
          }
        }

        _loadManagerNames(projects);
      }
    } catch (e) {
      debugPrint('[project_list_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadManagerNames(List<ProjectInfoVo> projects) async {
    final api = ref.read(projectApiProvider);
    for (final project in projects) {
      if (project.id == null) continue;
      try {
        final res = await api.getProjectStaffList(projectId: project.id!);
        if (res.isSuccess) {
          final members =
              (res.rows ?? []).where((m) => m.delFlag != 2).toList();
          final manager = members.where((m) => m.isProjectManager == 1);
          final name =
              manager.isNotEmpty ? manager.first.name : members.firstOrNull?.name;
          if (name != null && mounted) {
            setState(() => _managerNames[project.id!] = name);
          }
        }
      } catch (_) {}
    }
  }

  /// 按最后消息时间降序排列项目
  List<ProjectInfoVo> get _sortedProjects {
    final notificationState = ref.watch(notificationServiceProvider);
    final sorted = List<ProjectInfoVo>.from(_projects);
    sorted.sort((a, b) {
      final aTime = notificationState.unreadMap[a.id]?.lastTimestamp ?? 0;
      final bTime = notificationState.unreadMap[b.id]?.lastTimestamp ?? 0;
      if (aTime != bTime) return bTime.compareTo(aTime);
      // 无消息时间的按项目创建时间排
      final aCreate = a.projectCreateTime ?? a.createTime ?? '';
      final bCreate = b.projectCreateTime ?? b.createTime ?? '';
      return bCreate.compareTo(aCreate);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationServiceProvider);
    final sorted = _sortedProjects;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('项目消息')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sorted.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      indent: 76, // 头像(48) + 间距(16+12)
                      color: Color(0xFFEEEEEE),
                    ),
                    itemBuilder: (context, index) {
                      final project = sorted[index];
                      final projectId = project.id ?? 0;
                      final unreadInfo = notificationState.unreadMap[projectId];

                      return ConversationListItem(
                        projectName: project.projectName ?? '未命名项目',
                        lastContent: unreadInfo?.lastContent,
                        lastSenderName: unreadInfo?.lastSenderName,
                        lastTimestamp: unreadInfo?.lastTimestamp,
                        unreadCount: notificationState.getUnreadCount(projectId),
                        onTap: () => context.push(
                          '/project/progress?id=$projectId&name=${Uri.encodeComponent(project.projectName ?? '')}',
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Color(0xFFC7C7CC)),
          SizedBox(height: 12),
          Text('暂无项目消息',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
