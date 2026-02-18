// 添加/编辑家庭成员 - 对应 workDetail/familyAdd.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/register_models.dart';
import '../../../providers/register_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/submit_button.dart';

class FamilyAddPage extends ConsumerStatefulWidget {
  final int? index;
  final bool isEdit;

  const FamilyAddPage({super.key, this.index, this.isEdit = false});

  @override
  ConsumerState<FamilyAddPage> createState() => _FamilyAddPageState();
}

class _FamilyAddPageState extends ConsumerState<FamilyAddPage> {
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _relationCtl = TextEditingController();
  final _ageCtl = TextEditingController();
  final _occupationCtl = TextEditingController();
  final _politicalCtl = TextEditingController();
  final _remarkCtl = TextEditingController();
  String _hasMajorViolation = '0';
  bool _isSubmitting = false;
  int? _existingId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.index != null) _loadData();
  }

  Future<void> _loadData() async {
    final list = ref.read(registerProvider).familyList;
    if (widget.index! < list.length) {
      final item = list[widget.index!];
      setState(() {
        _existingId = item.id;
        _nameCtl.text = item.familyName ?? '';
        _phoneCtl.text = item.contactPhone ?? '';
        _relationCtl.text = item.relation ?? '';
        _ageCtl.text = (item.age ?? 0) > 0 ? item.age.toString() : '';
        _occupationCtl.text = item.occupation ?? '';
        _politicalCtl.text = item.politicalStatus ?? '';
        _hasMajorViolation = item.hasMajorViolation ?? '0';
        _remarkCtl.text = item.remark ?? '';
      });
    }
  }

  bool _validate() {
    final errors = <String>[];
    if (_nameCtl.text.trim().isEmpty) errors.add('姓名');
    if (_relationCtl.text.trim().isEmpty) errors.add('关系');
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
      final data = PersonnelFamilyRelationSubmit(
        id: _existingId,
        personnelId: pid,
        familyName: _nameCtl.text.trim(),
        relation: _relationCtl.text.trim(),
        contactPhone: _phoneCtl.text.trim().isNotEmpty
            ? _phoneCtl.text.trim()
            : null,
        age: _ageCtl.text.trim().isNotEmpty
            ? int.tryParse(_ageCtl.text.trim())
            : null,
        occupation: _occupationCtl.text.trim().isNotEmpty
            ? _occupationCtl.text.trim()
            : null,
        politicalStatus: _politicalCtl.text.trim().isNotEmpty
            ? _politicalCtl.text.trim()
            : null,
        hasMajorViolation: _hasMajorViolation,
        remark: _remarkCtl.text.trim().isNotEmpty
            ? _remarkCtl.text.trim()
            : null,
      );
      final res = _existingId != null
          ? await api.updateFamilyRelation(data)
          : await api.createFamilyRelation(data);
      if (res.isSuccess) {
        await ref.read(registerProvider.notifier).loadFamilyList();
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
      debugPrint('[family_add_page] Error: $e');
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
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _relationCtl.dispose();
    _ageCtl.dispose();
    _occupationCtl.dispose();
    _politicalCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑家庭成员' : '添加家庭成员'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: FormSection(title: '家庭成员', children: [
          FormRow(
            label: '姓名',
            required: true,
            child: TextField(
              controller: _nameCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入姓名',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '联系方式',
            child: TextField(
              controller: _phoneCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入联系方式',
              ),
              textAlign: TextAlign.end,
              keyboardType: TextInputType.phone,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '关系',
            required: true,
            child: TextField(
              controller: _relationCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入关系',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '年龄',
            child: TextField(
              controller: _ageCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入年龄',
              ),
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '职业',
            child: TextField(
              controller: _occupationCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入职业',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '政治面貌',
            child: TextField(
              controller: _politicalCtl,
              decoration: const InputDecoration.collapsed(
                hintText: '请输入政治面貌',
              ),
              textAlign: TextAlign.end,
              style: AppTypography.formField,
            ),
          ),
          FormRow(
            label: '重大违纪',
            isLast: true,
            child: PickerField(
              value: _hasMajorViolation == '1' ? '有' : '无',
              options: const ['无', '有'],
              onChanged: (v) => setState(
                () => _hasMajorViolation = v == '有' ? '1' : '0',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: TextField(
              controller: _remarkCtl,
              decoration: InputDecoration(
                hintText: '请输入备注',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(AppSpacing.s12),
              ),
              maxLines: 3,
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
