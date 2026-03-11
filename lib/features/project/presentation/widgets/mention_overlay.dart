import 'package:flutter/material.dart';

import '../../data/models/project_models.dart';

/// @成员选择浮层
/// 白底圆角卡片，最多显示 5 个成员
class MentionOverlay extends StatelessWidget {
  final List<ProjectStaffVo> filteredMembers;
  final ValueChanged<ProjectStaffVo> onSelect;
  final VoidCallback onDismiss;

  const MentionOverlay({
    super.key,
    required this.filteredMembers,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final displayMembers = filteredMembers.take(5).toList();
    if (displayMembers.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: displayMembers.length,
          itemBuilder: (_, index) {
            final member = displayMembers[index];
            final name = member.name ?? '';
            final initial = name.isNotEmpty ? name.characters.first : '?';
            final role = member.employeeRole ?? member.projectDuty ?? '';

            return InkWell(
              onTap: () => onSelect(member),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // 姓名首字母圆形头像
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCCCCC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 姓名
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 角色
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
