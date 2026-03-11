import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// 补卡申请页
class PunchCorrectPage extends ConsumerStatefulWidget {
  const PunchCorrectPage({super.key});

  @override
  ConsumerState<PunchCorrectPage> createState() => _PunchCorrectPageState();
}

class _PunchCorrectPageState extends ConsumerState<PunchCorrectPage> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  DateTime? _punchDate;
  String? _punchType;
  TimeOfDay? _punchTime;

  static const _punchTypes = ['上班打卡', '下班打卡'];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_punchDate == null) {
      _showToast('请选择补卡日期');
      return false;
    }
    if (_punchType == null) {
      _showToast('请选择补卡类型');
      return false;
    }
    if (_punchTime == null) {
      _showToast('请选择补卡时间');
      return false;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _showToast('请输入补卡原因');
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _punchDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (date != null && mounted) {
      setState(() => _punchDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _punchTime ?? TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() => _punchTime = time);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    return '${_pad(t.hour)}:${_pad(t.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('补卡申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildCard(
              title: '补卡信息',
              children: [
                _buildFormField(
                  label: '补卡日期',
                  required: true,
                  child: _buildSelector(
                    value: _formatDate(_punchDate),
                    placeholder: '请选择补卡日期',
                    onTap: _pickDate,
                  ),
                ),
                _buildFormField(
                  label: '补卡类型',
                  required: true,
                  child: _buildSelector(
                    value: _punchType,
                    placeholder: '请选择补卡类型',
                    onTap: _showPunchTypePicker,
                  ),
                ),
                _buildFormField(
                  label: '补卡时间',
                  required: true,
                  child: _buildSelector(
                    value: _formatTime(_punchTime),
                    placeholder: '请选择补卡时间',
                    onTap: _pickTime,
                  ),
                ),
                _buildFormField(
                  label: '补卡原因',
                  required: true,
                  child: _textArea(_reasonCtrl, '请输入补卡原因'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  void _showPunchTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '选择补卡类型',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5),
              ...List.generate(_punchTypes.length, (i) {
                final type = _punchTypes[i];
                final isSelected = _punchType == type;
                return ListTile(
                  title: Text(
                    type,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setState(() => _punchType = type);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
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
