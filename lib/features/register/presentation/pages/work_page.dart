// 注册 Step 4: 履历与家庭 - 对应 src/pages/register/work.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../constants/register_constants.dart';
import '../../data/models/register_models.dart';
import '../../providers/register_provider.dart';
import '../widgets/step_bar.dart';
import '../widgets/submit_button.dart';

class WorkPage extends ConsumerStatefulWidget {
  const WorkPage({super.key});

  @override
  ConsumerState<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends ConsumerState<WorkPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final notifier = ref.read(registerProvider.notifier);
    await Future.wait([
      notifier.loadResumeList(),
      notifier.loadFamilyList(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  List<PersonnelResumeVo> _filterByType(
    List<PersonnelResumeVo> list,
    int type,
  ) {
    return list.where((e) => e.experienceType == type).toList();
  }

  Future<void> _handleComplete() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(registerProvider.notifier).clear();
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registerProvider);
    final educationList = _filterByType(regState.resumeList, 1);
    final trainingList = _filterByType(regState.resumeList, 2);
    final workList = _filterByType(regState.resumeList, 3);
    final familyList = regState.familyList;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('履历与家庭')),
      body: Column(
        children: [
          const StepBar(current: 4, steps: RegisterConstants.stepLabels),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildCategory(
                            title: '学习经历',
                            items: educationList,
                            onAdd: () => context.push(
                              '/register/work-detail/education-add',
                            ),
                            itemBuilder: (item, index) => _buildResumeItem(
                              title: item.unitName ?? '未填写',
                              subtitle:
                                  '${item.startDate ?? ''} ~ ${item.endDate ?? ''}',
                              extra: item.education ?? item.major ?? '',
                              onTap: () => context.push(
                                '/register/work-detail/education-detail?index=$index',
                              ),
                            ),
                          ),
                          _buildCategory(
                            title: '培训经历',
                            items: trainingList,
                            onAdd: () => context.push(
                              '/register/work-detail/training-add',
                            ),
                            itemBuilder: (item, index) => _buildResumeItem(
                              title: item.unitName ?? '未填写',
                              subtitle:
                                  '${item.startDate ?? ''} ~ ${item.endDate ?? ''}',
                              extra: item.course ?? '',
                              onTap: () => context.push(
                                '/register/work-detail/training-detail?index=$index',
                              ),
                            ),
                          ),
                          _buildCategory(
                            title: '就职经历',
                            items: workList,
                            onAdd: () => context.push(
                              '/register/work-detail/work-add',
                            ),
                            itemBuilder: (item, index) => _buildResumeItem(
                              title: item.unitName ?? '未填写',
                              subtitle:
                                  '${item.startDate ?? ''} ~ ${item.endDate ?? ''}',
                              extra: item.position ?? '',
                              onTap: () => context.push(
                                '/register/work-detail/work-detail?index=$index',
                              ),
                            ),
                          ),
                          _buildCategory(
                            title: '家庭成员',
                            items: familyList,
                            onAdd: () => context.push(
                              '/register/work-detail/family-add',
                            ),
                            itemBuilder: (item, index) =>
                                _buildFamilyItem(item, index),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SubmitButton(
        label: '完成提交',
        backgroundColor: AppColors.success,
        onPressed: _handleComplete,
        isSubmitting: _isSubmitting,
      ),
    );
  }

  Widget _buildCategory<T>({
    required String title,
    required List<T> items,
    required VoidCallback onAdd,
    required Widget Function(T item, int index) itemBuilder,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.callout.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+ 添加',
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.backgroundPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
              child: Center(
                child: Text(
                  '暂无数据，点击添加',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((e) => itemBuilder(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _buildResumeItem({
    required String title,
    required String subtitle,
    required String extra,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.s10),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.s8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.formField.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    subtitle,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                  if (extra.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      extra,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.separatorNonOpaque,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyItem(PersonnelFamilyRelationVo item, int index) {
    return GestureDetector(
      onTap: () => context.push(
        '/register/work-detail/family-detail?index=$index',
      ),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.s10),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.s8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.familyName ?? '未填写',
                    style: AppTypography.formField.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '关系: ${item.relation ?? "未填写"}  联系方式: ${item.contactPhone ?? "未填写"}',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.separatorNonOpaque,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
