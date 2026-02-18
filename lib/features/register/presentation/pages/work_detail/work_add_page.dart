// 添加/编辑就职经历 - 对应 workDetail/workAdd.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/submit_button.dart';

class WorkAddPage extends ConsumerStatefulWidget {
  final int? index;
  final bool isEdit;

  const WorkAddPage({super.key, this.index, this.isEdit = false});

  @override
  ConsumerState<WorkAddPage> createState() => _WorkAddPageState();
}

class _WorkAddPageState extends ConsumerState<WorkAddPage> {
  final _unitNameCtl = TextEditingController();
  final _positionCtl = TextEditingController();
  final _salaryCtl = TextEditingController();
  final _leaveReasonCtl = TextEditingController();
  final _witnessNameCtl = TextEditingController();
  final _witnessContactCtl = TextEditingController();
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
    final list = ref
        .read(registerProvider)
        .resumeList
        .where((e) => e.experienceType == 3)
        .toList();
    if (widget.index! < list.length) {
      final item = list[widget.index!];
      setState(() {
        _existingId = item.id;
        _unitNameCtl.text = item.unitName ?? '';
        _positionCtl.text = item.position ?? '';
        _salaryCtl.text = item.salaryRange ?? '';
        _leaveReasonCtl.text = item.leaveReason ?? '';
        _witnessNameCtl.text = item.witnessName ?? '';
        _witnessContactCtl.text = item.witnessContact ?? '';
        _startDate = item.startDate ?? '';
        _endDate = item.endDate ?? '';
      });
    }
  }

  bool _validate() {
    final errors = <String>[];
    if (_unitNameCtl.text.trim().isEmpty) errors.add('单位名称');
    if (_positionCtl.text.trim().isEmpty) errors.add('所任职务');
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
      if (pid == null) return;
      final data = PersonnelResumeSubmit(
        id: _existingId,
        personnelId: pid,
        experienceType: 3,
        unitName: _unitNameCtl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        position: _positionCtl.text.trim().isNotEmpty
            ? _positionCtl.text.trim()
            : null,
        salaryRange: _salaryCtl.text.trim().isNotEmpty
            ? _salaryCtl.text.trim()
            : null,
        leaveReason: _leaveReasonCtl.text.trim().isNotEmpty
            ? _leaveReasonCtl.text.trim()
            : null,
        witnessName: _witnessNameCtl.text.trim().isNotEmpty
            ? _witnessNameCtl.text.trim()
            : null,
        witnessContact: _witnessContactCtl.text.trim().isNotEmpty
            ? _witnessContactCtl.text.trim()
            : null,
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
      debugPrint('[work_add_page] Error: $e');
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
    _positionCtl.dispose();
    _salaryCtl.dispose();
    _leaveReasonCtl.dispose();
    _witnessNameCtl.dispose();
    _witnessContactCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑就职经历' : '添加就职经历'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: FormSection(title: '就职经历', children: [
          FormRow(
            label: '单位名称',
            required: true,
            child: TextField(
              controller: _unitNameCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入单位名称',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '所任职务',
            required: true,
            child: TextField(
              controller: _positionCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入所任职务',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '薪资范围',
            child: TextField(
              controller: _salaryCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入薪资范围',
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
            label: '离职原因',
            child: TextField(
              controller: _leaveReasonCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入离职原因',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '证明人',
            child: TextField(
              controller: _witnessNameCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入证明人',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '证明人电话',
            isLast: true,
            child: TextField(
              controller: _witnessContactCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入证明人联系方式',
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
