// 添加/编辑学习经历 - 对应 workDetail/educationAdd.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/submit_button.dart';

class EducationAddPage extends ConsumerStatefulWidget {
  final int? index;
  final bool isEdit;

  const EducationAddPage({super.key, this.index, this.isEdit = false});

  @override
  ConsumerState<EducationAddPage> createState() => _EducationAddPageState();
}

class _EducationAddPageState extends ConsumerState<EducationAddPage> {
  final _unitNameCtl = TextEditingController();
  final _majorCtl = TextEditingController();
  final _educationCtl = TextEditingController();
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
    final regState = ref.read(registerProvider);
    final eduList =
        regState.resumeList.where((e) => e.experienceType == 1).toList();
    if (widget.index! < eduList.length) {
      final item = eduList[widget.index!];
      setState(() {
        _existingId = item.id;
        _unitNameCtl.text = item.unitName ?? '';
        _majorCtl.text = item.major ?? '';
        _educationCtl.text = item.education ?? '';
        _startDate = item.startDate ?? '';
        _endDate = item.endDate ?? '';
      });
    }
  }

  bool _validate() {
    final errors = <String>[];
    if (_unitNameCtl.text.trim().isEmpty) errors.add('学校名称');
    if (_majorCtl.text.trim().isEmpty) errors.add('专业');
    if (_startDate.isEmpty) errors.add('开始时间');
    if (_endDate.isEmpty) errors.add('结束时间');
    if (_educationCtl.text.trim().isEmpty) errors.add('学历');
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
      if (pid == null) return;
      final data = PersonnelResumeSubmit(
        id: _existingId,
        personnelId: pid,
        experienceType: 1,
        unitName: _unitNameCtl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        major: _majorCtl.text.trim(),
        education: _educationCtl.text.trim(),
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
      debugPrint('[education_add_page] Error: $e');
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
    _majorCtl.dispose();
    _educationCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑学习经历' : '添加学习经历'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: FormSection(title: '学习经历', children: [
          FormRow(
            label: '学校名称',
            required: true,
            child: TextField(
              controller: _unitNameCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入学校名称',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '专业',
            required: true,
            child: TextField(
              controller: _majorCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入专业',
              ),
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
            child: DatePickerField(
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
          ),
          FormRow(
            label: '学历',
            required: true,
            isLast: true,
            child: TextField(
              controller: _educationCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入学历',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
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
