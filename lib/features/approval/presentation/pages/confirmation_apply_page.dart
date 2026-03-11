import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// 转正申请页
class ConfirmationApplyPage extends ConsumerStatefulWidget {
  const ConfirmationApplyPage({super.key});

  @override
  ConsumerState<ConfirmationApplyPage> createState() =>
      _ConfirmationApplyPageState();
}

class _ConfirmationApplyPageState
    extends ConsumerState<ConfirmationApplyPage> {
  final _summaryCtrl = TextEditingController();
  bool _submitting = false;

  DateTime? _probationStart;
  DateTime? _probationEnd;
  DateTime? _confirmDate;

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_probationStart == null) {
      _showToast('请选择试用期开始日期');
      return false;
    }
    if (_probationEnd == null) {
      _showToast('请选择试用期结束日期');
      return false;
    }
    if (_probationEnd!.isBefore(_probationStart!)) {
      _showToast('试用期结束日期不能早于开始日期');
      return false;
    }
    if (_confirmDate == null) {
      _showToast('请选择申请转正日期');
      return false;
    }
    if (_summaryCtrl.text.trim().isEmpty) {
      _showToast('请输入试用期工作总结');
      return false;
    }
    return true;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      // TODO: 对接后端 API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('提交成功'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('提交失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate({required _DateField field}) async {
    final now = DateTime.now();
    DateTime initial;
    switch (field) {
      case _DateField.probationStart:
        initial = _probationStart ?? now;
      case _DateField.probationEnd:
        initial = _probationEnd ?? _probationStart ?? now;
      case _DateField.confirmDate:
        initial = _confirmDate ?? now;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    setState(() {
      switch (field) {
        case _DateField.probationStart:
          _probationStart = date;
        case _DateField.probationEnd:
          _probationEnd = date;
        case _DateField.confirmDate:
          _confirmDate = date;
      }
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('转正申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildCard(
              title: '转正信息',
              children: [
                _buildFormField(
                  label: '试用期开始日期',
                  required: true,
                  child: _buildSelector(
                    value: _formatDate(_probationStart),
                    placeholder: '请选择试用期开始日期',
                    onTap: () =>
                        _pickDate(field: _DateField.probationStart),
                  ),
                ),
                _buildFormField(
                  label: '试用期结束日期',
                  required: true,
                  child: _buildSelector(
                    value: _formatDate(_probationEnd),
                    placeholder: '请选择试用期结束日期',
                    onTap: () =>
                        _pickDate(field: _DateField.probationEnd),
                  ),
                ),
                _buildFormField(
                  label: '申请转正日期',
                  required: true,
                  child: _buildSelector(
                    value: _formatDate(_confirmDate),
                    placeholder: '请选择申请转正日期',
                    onTap: () =>
                        _pickDate(field: _DateField.confirmDate),
                  ),
                ),
                _buildFormField(
                  label: '试用期工作总结',
                  required: true,
                  child: _textArea(_summaryCtrl, '请输入试用期工作总结'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  // ========== 通用 UI 组件 ==========

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE5E5EA),
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                children: required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : placeholder,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black : AppColors.textPlaceholder,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textArea(TextEditingController ctrl, String placeholder) {
    return TextField(
      controller: ctrl,
      maxLines: 4,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: AppColors.textPlaceholder),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(12),
        counterStyle:
            TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
      style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.6),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.24),
          ),
          child: Text(
            _submitting ? '提交中...' : '提交申请',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum _DateField { probationStart, probationEnd, confirmDate }
