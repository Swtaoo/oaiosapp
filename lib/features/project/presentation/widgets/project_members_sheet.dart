import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/project_models.dart';

/// 项目成员底部弹窗
class ProjectMembersSheet extends StatelessWidget {
  final List<ProjectStaffVo> members;

  const ProjectMembersSheet({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '项目成员',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.neutral500),
              ),
            ],
          ),
        ),
        const Divider(height: 0.5),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: members.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    '暂无成员数据',
                    style: TextStyle(fontSize: 14, color: AppColors.neutral400),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final displayName = m.name ?? '用户${m.personnelId ?? m.id}';
                    final initial =
                        displayName.isNotEmpty ? displayName.characters.first : '?';
                    final role = m.isProjectManager == 1
                        ? '项目经理'
                        : (m.employeeRole ?? '成员');
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.neutral200,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ),
                      title: Text(displayName),
                      trailing: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
