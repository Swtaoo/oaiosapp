// 家庭成员详情 - 对应 workDetail/familyDetail.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/detail_action_bar.dart';

class FamilyDetailPage extends ConsumerWidget {
  final int index;

  const FamilyDetailPage({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(registerProvider).familyList;
    final item = index < list.length ? list[index] : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('家庭成员详情')),
      body: item == null
          ? const Center(child: Text('数据不存在'))
          : SingleChildScrollView(
              child: FormSection(title: '家庭成员', children: [
                DetailRow(label: '姓名', value: item.familyName ?? ''),
                DetailRow(label: '联系方式', value: item.contactPhone ?? ''),
                DetailRow(label: '关系', value: item.relation ?? ''),
                DetailRow(
                  label: '年龄',
                  value: (item.age ?? 0) > 0 ? '${item.age}岁' : '',
                ),
                DetailRow(label: '职业', value: item.occupation ?? ''),
                DetailRow(label: '政治面貌', value: item.politicalStatus ?? ''),
                DetailRow(
                  label: '重大违纪违法',
                  value: item.hasMajorViolation == '1' ? '有' : '无',
                ),
                DetailRow(label: '备注', value: item.remark ?? '', isLast: true),
              ]),
            ),
      bottomNavigationBar: DetailActionBar(
        onDelete: () => _handleDelete(context, ref, item),
        onEdit: () => context.push(
          '/register/work-detail/family-add?index=$index&mode=edit',
        ),
      ),
    );
  }

  void _handleDelete(
    BuildContext context,
    WidgetRef ref,
    PersonnelFamilyRelationVo? item,
  ) {
    if (item?.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条家庭成员信息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(registerApiProvider);
              final res = await api.deleteFamilyRelation([item!.id!]);
              if (res.isSuccess) {
                await ref.read(registerProvider.notifier).loadFamilyList();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                  context.pop();
                }
              }
            },
            child: Text(
              '删除',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
