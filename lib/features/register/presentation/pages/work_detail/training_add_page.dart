// 添加/编辑培训经历 - 对应 workDetail/trainingAdd.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/submit_button.dart';

class TrainingAddPage extends ConsumerStatefulWidget {
  final int? index;
  final bool isEdit;

  const TrainingAddPage({super.key, this.index, this.isEdit = false});

  @override
  ConsumerState<TrainingAddPage> createState() => _TrainingAddPageState();
}

class _TrainingAddPageState extends ConsumerState<TrainingAddPage> {
  final _unitNameCtl = TextEditingController();
  final _courseCtl = TextEditingController();
  String _startDate = '';
  String _endDate = '';
  bool _isSubmitting = false;
  int? _existingId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.index != null) _loadData();
  }

  Future<void> _loadData() async {
    var list = ref
        .read(registerProvider)
        .resumeList
        .where((e) => e.experienceType == 2)
        .toList();
    if (list.isEmpty) {
      await ref.read(registerProvider.notifier).loadResumeList();
      list = ref
          .read(registerProvider)
          .resumeList
          .where((e) => e.experienceType == 2)
          .toList();
    }
    if (widget.index! < list.length) {
      final item = list[widget.index!];
      setState(() {
        _existingId = item.id;
        _unitNameCtl.text = item.unitName ?? '';
        _courseCtl.text = item.course ?? '';
        _startDate = item.startDate ?? '';
        _endDate = item.endDate ?? '';
      });
    }
  }

  bool _validate() {
    final errors = <String>[];
    if (_unitNameCtl.text.trim().isEmpty) errors.add('培训机构');
    if (_courseCtl.text.trim().isEmpty) errors.add('培训课程');
    if (_startDate.isEmpty) errors.add('开始时间');
    if (_endDate.isEmpty) errors.add('结束时间');
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写${errors.join("、")}')),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(registerApiProvider);
      final pid = ref.read(registerProvider).personnelId;
      if (pid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未获取到人员信息，请返回重试')),
          );
        }
        return;
      }
      final data = PersonnelResumeSubmit(
        id: _existingId,
        personnelId: pid,
        experienceType: 2,
        unitName: _unitNameCtl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        course: _courseCtl.text.trim(),
      );
      final res = _existingId != null
          ? await api.updateResume(data)
          : await api.createResume(data);
      if (res.isSuccess) {
        await ref.read(registerProvider.notifier).loadResumeList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? '编辑成功' : '添加成功'),
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.errorMessage)),
          );
        }
      }
    } catch (e) {
      debugPrint('[training_add_page] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _unitNameCtl.dispose();
    _courseCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑培训经历' : '添加培训经历'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: FormSection(title: '培训经历', children: [
          FormRow(
            label: '培训机构',
            required: true,
            child: TextField(
              controller: _unitNameCtl,
              decoration: formInputDecoration(hint: '请输入培训机构'),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '培训课程',
            required: true,
            child: TextField(
              controller: _courseCtl,
              decoration: formInputDecoration(hint: '请输入培训课程'),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '开始时间',
            required: true,
            child: DatePickerField(
              value: _startDate,
              onChanged: (v) => setState(() => _startDate = v),
            ),
          ),
          FormRow(
            label: '结束时间',
            required: true,
            isLast: true,
            child: DatePickerField(
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: SubmitButton(
        label: '保存',
        onPressed: _handleSave,
        isSubmitting: _isSubmitting,
      ),
    );
  }
}
