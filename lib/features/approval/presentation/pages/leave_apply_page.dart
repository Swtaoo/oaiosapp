import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../register/presentation/widgets/oss_upload.dart';
import '../../data/api/approval_api.dart';
import '../../data/models/approval_models.dart';

/// 请假申请页
class LeaveApplyPage extends ConsumerStatefulWidget {
  const LeaveApplyPage({super.key});

  @override
  ConsumerState<LeaveApplyPage> createState() => _LeaveApplyPageState();
}

class _LeaveApplyPageState extends ConsumerState<LeaveApplyPage> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  String? _leaveType;
  DateTime? _startTime;
  DateTime? _endTime;
  final List<String> _attachmentUrls = [];

  static const _leaveTypes = [
    '事假',
    '病假',
    '年假',
    '婚假',
    '产假',
    '丧假',
    '调休',
    '其他',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// 请假总分钟数
  int get _leaveTotalMinutes {
    if (_startTime == null || _endTime == null) return 0;
    final diff = _endTime!.difference(_startTime!);
    return diff.isNegative ? 0 : diff.inMinutes;
  }

  /// 以 8 小时工作日换算的天数（精确到分钟），用于提交
  double get _leaveDaysDecimal => _leaveTotalMinutes / (8 * 60);

  /// 显示用：「X 小时 Y 分钟（Z 天）」
  String get _leaveDaysDisplay {
    final total = _leaveTotalMinutes;
    if (total <= 0) return '';
    final hours = total ~/ 60;
    final minutes = total % 60;
    final days = _leaveDaysDecimal;

    final timeParts = <String>[
      if (hours > 0) '$hours 小时',
      if (minutes > 0) '$minutes 分钟',
    ];
    final timeStr = timeParts.join(' ');

    // 若天数是整数则不显示小数
    final daysStr = days == days.floorToDouble()
        ? '${days.toInt()} 天'
        : '${days.toStringAsFixed(2)} 天';

    return '$timeStr（$daysStr）';
  }

  bool _validate() {
    if (_leaveType == null) {
      _showToast('请选择请假类型');
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
    if (_endTime!.isBefore(_startTime!) || !_endTime!.isAfter(_startTime!)) {
      _showToast('结束时间必须晚于开始时间');
      return false;
    }
    if (_leaveTotalMinutes <= 0) {
      _showToast('请假时长不能为 0');
      return false;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _showToast('请输入请假事由');
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
      final api = ApprovalApi(ref.read(dioProvider));
      final data = LeaveApplicationSubmit(
        leaveType: _leaveType!,
        startTime: _formatDateTimeForApi(_startTime!),
        endTime: _formatDateTimeForApi(_endTime!),
        leaveDays: _leaveDaysDecimal,
        reason: _reasonCtrl.text.trim(),
        attachments:
            _attachmentUrls.isEmpty ? null : jsonEncode(_attachmentUrls),
      );
      final res = await api.submitLeave(data);
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('提交成功'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
      } else {
        _showToast(res.message ?? '提交失败');
      }
    } catch (e) {
      if (mounted) {
        _showToast('提交失败: $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startTime ?? now)
        : (_endTime ?? _startTime ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  /// 给后端用的格式（带秒，与 Jackson "yyyy-MM-dd HH:mm:ss" 对齐）
  String _formatDateTimeForApi(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}:00';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('请假申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildCard(
              title: '请假信息',
              children: [
                _buildFormField(
                  label: '请假类型',
                  required: true,
                  child: _buildSelector(
                    value: _leaveType,
                    placeholder: '请选择请假类型',
                    onTap: _showLeaveTypePicker,
                  ),
                ),
                _buildFormField(
                  label: '开始时间',
                  required: true,
                  child: _buildSelector(
                    value: _formatDateTime(_startTime),
                    placeholder: '请选择开始时间',
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                ),
                _buildFormField(
                  label: '结束时间',
                  required: true,
                  child: _buildSelector(
                    value: _formatDateTime(_endTime),
                    placeholder: '请选择结束时间',
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                ),
                _buildFormField(
                  label: '请假时长',
                  child: _readonlyField(
                    _leaveTotalMinutes <= 0 ? '-' : _leaveDaysDisplay,
                  ),
                ),
                _buildFormField(
                  label: '请假事由',
                  required: true,
                  child: _textArea(_reasonCtrl, '请输入请假事由'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '附件',
              children: [
                _buildFormField(
                  label: '上传附件（可选）',
                  child: OssUpload(
                    maxCount: 5,
                    addButtonText: '上传图片',
                    onSuccess: (result) {
                      setState(() => _attachmentUrls.add(result.url));
                    },
                    onRemove: (item) {
                      setState(() => _attachmentUrls.remove(item.url));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  void _showLeaveTypePicker() {
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
                      '选择请假类型',
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _leaveTypes.length,
                  itemBuilder: (ctx, i) {
                    final type = _leaveTypes[i];
                    final isSelected = _leaveType == type;
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
                        setState(() => _leaveType = type);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
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
