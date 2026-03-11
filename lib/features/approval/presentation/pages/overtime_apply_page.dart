import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// 加班申请页
class OvertimeApplyPage extends ConsumerStatefulWidget {
  const OvertimeApplyPage({super.key});

  @override
  ConsumerState<OvertimeApplyPage> createState() => _OvertimeApplyPageState();
}

class _OvertimeApplyPageState extends ConsumerState<OvertimeApplyPage> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  DateTime? _overtimeDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// 计算加班时长（小时）
  String get _overtimeHours {
    if (_startTime == null || _endTime == null) return '';
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    int endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    // 跨天：如 22:00 ~ 02:00
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    final diff = endMinutes - startMinutes;
    final hours = diff / 60;
    // 精确到 0.5
    final rounded = (hours * 2).ceil() / 2;
    return rounded % 1 == 0
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
  }

  bool _validate() {
    if (_overtimeDate == null) {
      _showToast('请选择加班日期');
      return false;
    }
    if (_startTime == null) {
      _showToast('请选择开始时间');
      return false;
    }
    if (_endTime == null) {
      _showToast('请选择结束时间');
      return false;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _showToast('请输入加班原因');
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
      initialDate: _overtimeDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date != null && mounted) {
      setState(() => _overtimeDate = date);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
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
      appBar: AppBar(title: const Text('加班申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildCard(
              title: '加班信息',
              children: [
                _buildFormField(
                  label: '加班日期',
                  required: true,
                  child: _buildSelector(
                    value: _formatDate(_overtimeDate),
                    placeholder: '请选择加班日期',
                    onTap: _pickDate,
                  ),
                ),
                _buildFormField(
                  label: '开始时间',
                  required: true,
                  child: _buildSelector(
                    value: _formatTime(_startTime),
                    placeholder: '请选择开始时间',
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                _buildFormField(
                  label: '结束时间',
                  required: true,
                  child: _buildSelector(
                    value: _formatTime(_endTime),
                    placeholder: '请选择结束时间',
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
                _buildFormField(
                  label: '加班时长',
                  child: _readonlyField(
                    _overtimeHours.isEmpty ? '-' : '$_overtimeHours 小时',
                  ),
                ),
                _buildFormField(
                  label: '加班原因',
                  required: true,
                  child: _textArea(_reasonCtrl, '请输入加班原因'),
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

  Widget _readonlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
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
