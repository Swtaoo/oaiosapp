import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/utils/approval_utils.dart';
import '../../../register/presentation/widgets/oss_upload.dart';

/// 审批操作区域 - 根据 displayStatus 动态渲染
class ApprovalActions extends StatefulWidget {
  final bool isSubmitting;
  final String? displayStatus;
  final int currentUserId;
  final int? objectId;
  final String? approvalObjectType;
  final String? paymentVoucher;
  final Future<void> Function({
    required String opinion,
    required String status,
  }) onSubmit;
  final Future<void> Function(String paymentVoucher)? onUploadPaymentVoucher;

  const ApprovalActions({
    super.key,
    this.isSubmitting = false,
    this.displayStatus,
    this.currentUserId = 0,
    this.objectId,
    this.approvalObjectType,
    this.paymentVoucher,
    required this.onSubmit,
    this.onUploadPaymentVoucher,
  });

  @override
  State<ApprovalActions> createState() => _ApprovalActionsState();
}

class _ApprovalActionsState extends State<ApprovalActions> {
  final _commentController = TextEditingController();
  String? _uploadedVoucherUrl;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isSunLin => widget.currentUserId == ApiConstants.approverSunLin;

  bool get _canApprove => widget.displayStatus == 'myPending';

  void _handleSubmit(String status) {
    final opinion = _commentController.text.trim();
    if (opinion.isEmpty) {
      _showAlert('提示', '请输入审批意见');
      return;
    }

    final confirmText = status == '1' ? '确定同意该申请吗？' : '确定驳回该申请吗？';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认审批'),
        content: Text(confirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSubmit(opinion: opinion, status: status);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 已支付 → 显示支付凭证（只读）
    if (widget.displayStatus == 'paid') {
      return _buildPaidView();
    }

    // 已审批但不是已支付 → 只读状态提示
    if (widget.displayStatus == 'approved') {
      return _buildReadOnlyStatus('已审批', '该申请已完成审批，等待付款');
    }

    // pending（等待他人审批）→ 只读状态提示
    if (widget.displayStatus == 'pending') {
      return _buildReadOnlyStatus('待审批', '该申请正在等待其他审批人处理');
    }

    // myPending → 可操作
    if (_canApprove) {
      return _buildApprovalForm();
    }

    // 兜底
    return const SizedBox.shrink();
  }

  /// 审批表单（通过/驳回 + 孙林上传凭证）
  Widget _buildApprovalForm() {
    return Column(
      children: [
        // 孙林额外的支付凭证上传区域
        if (_isSunLin && widget.approvalObjectType == '1')
          _buildPaymentVoucherUpload(),

        // 审批意见卡片
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.separatorNonOpaque,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          '审批意见',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '请输入审批意见',
                    hintStyle: TextStyle(color: AppColors.textPlaceholder),
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 提交按钮
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => _handleSubmit('2'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    '驳回',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => _handleSubmit('1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 4,
                    shadowColor:
                        AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    widget.isSubmitting ? '提交中...' : '通过',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 支付凭证上传区域（仅孙林 + 资金申请）
  Widget _buildPaymentVoucherUpload() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.separatorNonOpaque,
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '上传支付凭证',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          OssUpload(
            maxCount: 1,
            onSuccess: (result) {
              setState(() => _uploadedVoucherUrl = result.url);
              widget.onUploadPaymentVoucher?.call(result.url);
            },
          ),
          if (_uploadedVoucherUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '凭证已上传',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 已支付状态 - 显示支付凭证
  Widget _buildPaidView() {
    final voucherUrls = parseAttachmentUrls(widget.paymentVoucher);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.separatorNonOpaque,
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Text(
                      '支付凭证',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAF52DE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已支付',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAF52DE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (voucherUrls.isEmpty)
            Text(
              '暂无支付凭证',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: voucherUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    url,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.separatorNonOpaque,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textTertiary, size: 28),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 只读状态提示
  Widget _buildReadOnlyStatus(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
