// 注册 Step 3: 入职规划 - 对应 src/pages/register/plan.vue

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
import '../widgets/form_widgets.dart';
import '../widgets/submit_button.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  final _positionCtl = TextEditingController();
  final _salaryCtl = TextEditingController();
  final _careerCtl = TextEditingController();
  final _evalCtl = TextEditingController();

  String _canOvertime = '';
  String _canWorkRemote = '';
  bool _isSubmitting = false;
  bool _isLoading = true;
  int? _existingPlanId;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final state = ref.read(registerProvider);
    final pid = state.personnelId;
    if (pid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final api = ref.read(registerApiProvider);
      final res = await api.getEntryPlanList(personnelId: pid);
      if (res.isSuccess && res.rows != null && res.rows!.isNotEmpty) {
        final plan = res.rows!.first;
        setState(() {
          _existingPlanId = plan.id;
          _positionCtl.text = plan.appliedPosition ?? '';
          _salaryCtl.text = plan.expectedSalary != null
              ? plan.expectedSalary.toString()
              : '';
          _canOvertime = plan.canOvertime == 1
              ? '是'
              : (plan.canOvertime == 0 ? '否' : '');
          _canWorkRemote = plan.canWorkRemote == 1
              ? '是'
              : (plan.canWorkRemote == 0 ? '否' : '');
          _careerCtl.text = plan.careerPlanning ?? '';
          _evalCtl.text = plan.selfEvaluation ?? '';
        });
      }
    } catch (e) {
      debugPrint('[plan_page] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _validate() {
    if (_positionCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写应聘职位')),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(registerApiProvider);
      final pid = ref.read(registerProvider).personnelId;
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到人员信息')),
        );
        return;
      }

      final data = PersonnelEntryPlanSubmit(
        id: _existingPlanId,
        personnelId: pid,
        appliedPosition: _positionCtl.text.trim(),
        expectedSalary: _salaryCtl.text.trim().isNotEmpty
            ? num.tryParse(_salaryCtl.text.trim())
            : null,
        canOvertime:
            _canOvertime == '是' ? 1 : (_canOvertime == '否' ? 0 : null),
        canWorkRemote: _canWorkRemote == '是'
            ? 1
            : (_canWorkRemote == '否' ? 0 : null),
        careerPlanning: _careerCtl.text.trim().isNotEmpty
            ? _careerCtl.text.trim()
            : null,
        selfEvaluation: _evalCtl.text.trim().isNotEmpty
            ? _evalCtl.text.trim()
            : null,
      );

      final res = _existingPlanId != null
          ? await api.updateEntryPlan(data)
          : await api.createEntryPlan(data);

      if (res.isSuccess) {
        ref.read(registerProvider.notifier).setStep(4);
        if (mounted) context.push('/register/work');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _positionCtl.dispose();
    _salaryCtl.dispose();
    _careerCtl.dispose();
    _evalCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('入职规划')),
      body: Column(
        children: [
          const StepBar(current: 3, steps: RegisterConstants.stepLabels),
          Expanded(
            child: _isLoading
                ? const FormLoadingPlaceholder()
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        FormSection(title: '职位信息', children: [
                          FormRow(
                            label: '应聘职位',
                            required: true,
                            child: TextField(
                              controller: _positionCtl,
                              decoration: const InputDecoration.collapsed(
                                hintText: '请输入应聘职位',
                              ),
                              textAlign: TextAlign.end,
                              style: AppTypography.formField,
                            ),
                          ),
                          FormRow(
                            label: '期望薪资',
                            child: TextField(
                              controller: _salaryCtl,
                              decoration: const InputDecoration.collapsed(
                                hintText: '请输入期望薪资',
                              ),
                              textAlign: TextAlign.end,
                              keyboardType: TextInputType.number,
                              style: AppTypography.formField,
                            ),
                          ),
                          FormRow(
                            label: '能否加班',
                            child: PickerField(
                              value: _canOvertime,
                              options: RegisterConstants.yesNoOptions,
                              onChanged: (v) =>
                                  setState(() => _canOvertime = v),
                            ),
                          ),
                          FormRow(
                            label: '能否出差',
                            isLast: true,
                            child: PickerField(
                              value: _canWorkRemote,
                              options: RegisterConstants.yesNoOptions,
                              onChanged: (v) =>
                                  setState(() => _canWorkRemote = v),
                            ),
                          ),
                        ]),
                        FormSection(title: '自我评价', children: [
                          TextField(
                            controller: _careerCtl,
                            decoration: InputDecoration(
                              hintText: '请输入职业规划',
                              border: const OutlineInputBorder(),
                              contentPadding:
                                  const EdgeInsets.all(AppSpacing.s12),
                            ),
                            maxLines: 3,
                            style: AppTypography.formField,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          TextField(
                            controller: _evalCtl,
                            decoration: InputDecoration(
                              hintText: '请输入自我评价',
                              border: const OutlineInputBorder(),
                              contentPadding:
                                  const EdgeInsets.all(AppSpacing.s12),
                            ),
                            maxLines: 3,
                            style: AppTypography.formField,
                          ),
                        ]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SubmitButton(
        onPressed: _handleSubmit,
        isSubmitting: _isSubmitting,
      ),
    );
  }
}
