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
                            icon: Icons.school_outlined,
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
                            icon: Icons.menu_book_outlined,
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
                            icon: Icons.work_outline_rounded,
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
                            icon: Icons.people_outline_rounded,
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
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
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
          // 分区标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.s14,
              AppSpacing.s8,
              AppSpacing.s10,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.callout.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // 添加按钮 — 保证 44pt 触摸区
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12,
                        vertical: AppSpacing.s10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Text(
                            '添加',
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpacing.pagePadding,
            endIndent: AppSpacing.pagePadding,
            color: AppColors.neutral200,
          ),
          if (items.isEmpty)
            _EmptyHint(onAdd: onAdd)
          else ...[
            const SizedBox(height: AppSpacing.s8),
            ...items.asMap().entries.map((e) => itemBuilder(e.value, e.key)),
            const SizedBox(height: AppSpacing.s8),
          ],
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
    return _RecordTile(
      title: title,
      subtitle: subtitle,
      extra: extra.isNotEmpty ? extra : null,
      onTap: onTap,
    );
  }

  Widget _buildFamilyItem(PersonnelFamilyRelationVo item, int index) {
    return _RecordTile(
      title: item.familyName ?? '未填写',
      subtitle: item.relation ?? '未填写',
      extra: item.contactPhone?.isNotEmpty == true ? item.contactPhone : null,
      onTap: () => context.push(
        '/register/work-detail/family-detail?index=$index',
      ),
    );
  }
}

// ─── 记录卡片 ───────────────────────────────────
class _RecordTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? extra;
  final VoidCallback onTap;

  const _RecordTile({
    required this.title,
    required this.subtitle,
    this.extra,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      subtitle,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    if (extra != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        extra!,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral300,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 空状态引导 ──────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 28,
                color: AppColors.neutral300,
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                '点击添加',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
