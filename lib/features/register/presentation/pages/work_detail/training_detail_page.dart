// 培训经历详情 - 对应 workDetail/trainingDetail.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/detail_action_bar.dart';

class TrainingDetailPage extends ConsumerWidget {
  final int index;

  const TrainingDetailPage({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref
        .watch(registerProvider)
        .resumeList
        .where((e) => e.experienceType == 2)
        .toList();
    final item = index < list.length ? list[index] : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('培训经历详情')),
      body: item == null
          ? const Center(child: Text('数据不存在'))
          : SingleChildScrollView(
              child: FormSection(title: '培训经历', children: [
                DetailRow(label: '培训机构', value: item.unitName ?? ''),
                DetailRow(label: '培训课程', value: item.course ?? ''),
                DetailRow(label: '开始时间', value: item.startDate ?? ''),
                DetailRow(label: '结束时间', value: item.endDate ?? '', isLast: true),
              ]),
            ),
      bottomNavigationBar: DetailActionBar(
        onDelete: () => _handleDelete(context, ref, item),
        onEdit: () => context.push(
          '/register/work-detail/training-add?index=$index&mode=edit',
        ),
      ),
    );
  }

  void _handleDelete(
    BuildContext context,
    WidgetRef ref,
    PersonnelResumeVo? item,
  ) {
    if (item?.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条培训经历吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(registerApiProvider);
              final res = await api.deleteResume([item!.id!]);
              if (res.isSuccess) {
                await ref.read(registerProvider.notifier).loadResumeList();
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
