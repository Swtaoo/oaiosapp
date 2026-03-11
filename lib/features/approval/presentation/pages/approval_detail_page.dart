import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/approval_models.dart';
import '../../data/utils/approval_utils.dart';
import '../../providers/approval_provider.dart';
import '../widgets/approval_actions.dart';
import '../widgets/approval_timeline.dart';

/// 审批详情页 (3合1) - 对应 src/pages/approval/index.vue
class ApprovalDetailPage extends ConsumerStatefulWidget {
  final int objectId;
  final String approvalObjectType; // '1'资金 '2'工资 '3'报销

  const ApprovalDetailPage({
    super.key,
    required this.objectId,
    required this.approvalObjectType,
  });

  @override
  ConsumerState<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends ConsumerState<ApprovalDetailPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  // 资金
  FundApplicationVo? _fundData;
  String? _paymentVoucher;

  // 工资
  SalaryInfoVo? _salaryData;
  List<SalaryDetailVo> _salaryDetailList = [];

  // 报销
  ReimbursementVo? _reimbursementData;
  List<ReimbursementDetailVo> _reimbursementDetailList = [];

  // 公共
  List<ApprovalFlowVo> _approvalFlowList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 推断当前用户的 displayStatus
  String? _inferDisplayStatus(int currentUserId) {
    if (_approvalFlowList.isEmpty) return null;

    // 按创建时间排序后，找到第一个未审批的节点
    // 只有该节点的审批人是当前用户时才是 myPending
    ApprovalFlowVo? firstPendingNode;
    for (final flow in _approvalFlowList) {
      if (flow.isDeleted) continue;
      final s = flow.status;
      // status == '0' 或 null/空 表示待审批
      if (s == '0' || s == null || s.isEmpty) {
        firstPendingNode = flow;
        break;
      }
    }

    if (firstPendingNode != null) {
      if (firstPendingNode.approverId == currentUserId) {
        return 'myPending';
      }
      return 'pending';
    }

    // 所有节点都已处理
    // 检查是否有驳回
    final hasRejected = _approvalFlowList.any(
      (f) => !f.isDeleted && (f.status == '2' || f.status == 'rejected'),
    );
    if (hasRejected) return 'approved';

    // 全部通过
    if (widget.approvalObjectType == '1' &&
        _paymentVoucher != null &&
        _paymentVoucher!.isNotEmpty) {
      return 'paid';
    }
    return 'approved';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(approvalApiProvider);

      // 根据类型加载对应数据
      switch (widget.approvalObjectType) {
        case '1': // 资金
          final res = await api.getFundApplication(widget.objectId);
          if (res.isSuccess && res.data != null) {
            _fundData = res.data;
            _paymentVoucher = res.data?.paymentVoucher;
          }
        case '2': // 工资
          final res = await api.getSalaryInfo(widget.objectId);
          if (res.isSuccess && res.data != null) _salaryData = res.data;
          final detailRes = await api.getSalaryDetailList(
            salaryId: widget.objectId,
          );
          if (detailRes.isSuccess && detailRes.rows != null) {
            _salaryDetailList = detailRes.rows!
                .where((e) => !e.isDeleted)
                .toList();
          }
        case '3': // 报销
          final res = await api.getReimbursement(widget.objectId);
          if (res.isSuccess && res.data != null) _reimbursementData = res.data;
          final detailRes = await api.getReimbursementDetailList(
            reimbursementId: widget.objectId,
          );
          if (detailRes.isSuccess && detailRes.rows != null) {
            _reimbursementDetailList = detailRes.rows!
                .where((e) => !e.isDeleted)
                .toList();
          }
      }

      // 加载审批流程
      final flowRes = await api.getApprovalFlowList(
        approvalObjectType: widget.approvalObjectType,
        objectId: widget.objectId,
      );
      if (flowRes.isSuccess && flowRes.rows != null) {
        _approvalFlowList = flowRes.rows!.where((e) => !e.isDeleted).toList()
          ..sort((a, b) {
            final timeA = a.createTime != null
                ? DateTime.tryParse(a.createTime!)?.millisecondsSinceEpoch ?? 0
                : 0;
            final timeB = b.createTime != null
                ? DateTime.tryParse(b.createTime!)?.millisecondsSinceEpoch ?? 0
                : 0;
            return timeA.compareTo(timeB);
          });
      }
    } catch (e, stack) {
      debugPrint('[ApprovalDetail] _loadData error: $e\n$stack');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 找到当前用户的待审批节点
  ApprovalFlowVo? _findMyPendingFlow(int currentUserId) {
    for (final flow in _approvalFlowList) {
      if (flow.isDeleted) continue;
      final s = flow.status;
      if (s == '0' || s == null || s.isEmpty) {
        if (flow.approverId == currentUserId) {
          return flow;
        }
        break; // 只看第一个待审批节点
      }
    }
    return null;
  }

  Future<void> _handleSubmit({
    required String opinion,
    required String status,
  }) async {
    final userId = ref.read(currentUserProvider)?.effectiveUserId ?? 0;
    if (userId <= 0) return;

    final pendingFlow = _findMyPendingFlow(userId);
    if (pendingFlow == null || pendingFlow.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('未找到待审批节点'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(approvalApiProvider);
      final res = await api.submitApproval(
        ApprovalFlowSubmit(
          id: pendingFlow.id!,
          approvalObjectType: widget.approvalObjectType,
          objectId: widget.objectId,
          approverId: userId,
          approvalOpinion: opinion,
          approvalRemark: opinion,
          nextApproverId: pendingFlow.nextApproverId ?? 0,
          isFinalApproval: pendingFlow.isFinalApproval ?? 0,
          status: status,
        ),
      );
      if (res.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == '1' ? '审批通过' : '已驳回'),
            backgroundColor: AppColors.success,
          ),
        );
        // 刷新列表后返回
        ref.read(approvalListProvider.notifier).refresh();
        ref.invalidate(myPendingCountProvider);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交审批失败'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleUploadPaymentVoucher(String voucherUrl) async {
    try {
      final api = ref.read(approvalApiProvider);
      final res = await api.updatePaymentVoucher(
        id: widget.objectId,
        paymentVoucher: voucherUrl,
      );
      if (res.isSuccess && mounted) {
        setState(() => _paymentVoucher = voucherUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('支付凭证上传成功'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('上传支付凭证失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String get _pageTitle {
    switch (widget.approvalObjectType) {
      case '1':
        return '资金审批';
      case '2':
        return '工资审批';
      case '3':
        return '报销审批';
      default:
        return '文件审批';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.effectiveUserId ?? 0;
    final displayStatus = _inferDisplayStatus(currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: Text(_pageTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  // 类型相关的信息卡片
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // 审批流程时间线
                  ApprovalTimeline(flowList: _approvalFlowList),
                  const SizedBox(height: 16),

                  // 审批操作区域
                  ApprovalActions(
                    isSubmitting: _isSubmitting,
                    displayStatus: displayStatus,
                    currentUserId: currentUserId,
                    objectId: widget.objectId,
                    approvalObjectType: widget.approvalObjectType,
                    paymentVoucher: _paymentVoucher,
                    onSubmit: ({required opinion, required status}) =>
                        _handleSubmit(opinion: opinion, status: status),
                    onUploadPaymentVoucher: _handleUploadPaymentVoucher,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    switch (widget.approvalObjectType) {
      case '1':
        return _buildFundCard();
      case '2':
        return _buildSalaryCard();
      case '3':
        return _buildReimbursementCard();
      default:
        return const SizedBox.shrink();
    }
  }

  // ========== 资金申请卡片 ==========
  Widget _buildFundCard() {
    final attachmentUrls = parseAttachmentUrls(_fundData?.attachment);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('申请信息'),
          _infoRow('申请部门', _fundData?.applyDepartment ?? '-'),
          _infoRow('申请人', _fundData?.applicant ?? '-'),
          _infoRow(
            '申请金额',
            '\u00A5${formatAmount(_fundData?.applyAmount)}',
            isAmount: true,
          ),

          // 资金项目（上下布局）
          _verticalField('申请资金项目', _fundData?.fundProject ?? '-'),
          const SizedBox(height: 12),

          // 费用说明（上下布局）
          _verticalField('申请资金费用', _fundData?.fundCostDesc ?? '-'),
          const SizedBox(height: 12),

          // 附件
          _verticalFieldLabel('附件'),
          const SizedBox(height: 8),
          if (attachmentUrls.isEmpty)
            Text(
              '暂无附件',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attachmentUrls.map((url) {
                return GestureDetector(
                  onTap: () => _previewImages(attachmentUrls),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.separatorNonOpaque,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ========== 工资卡片 ==========
  Widget _buildSalaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('工资申请信息'),
          _infoRow('应发月份', _salaryData?.paymentDate ?? '-'),
          _infoRow(
            '基本工资总额',
            '\u00A5${formatAmount(_salaryData?.basicSalaryTotal)}',
          ),
          _infoRow('补贴总额', '\u00A5${formatAmount(_salaryData?.subsidyTotal)}'),
          _infoRow(
            '保险公积金总额',
            '\u00A5${formatAmount(_salaryData?.insuranceFundTotal)}',
          ),
          _infoRow(
            '应发金额总额',
            '\u00A5${formatAmount(_salaryData?.payableAmountTotal)}',
          ),
          _infoRow(
            '实发金额总额',
            '\u00A5${formatAmount(_salaryData?.actualAmountTotal)}',
          ),
          _infoRow('未发金额', '\u00A5${formatAmount(_salaryData?.unpaidAmount)}'),
          _infoRow(
            '总金额',
            '\u00A5${formatAmount(_salaryData?.unpaidAmount)}',
            isAmount: true,
          ),

          // 工资明细
          _detailSectionHeader('工资明细'),
          if (_salaryDetailList.isEmpty)
            _emptyDetail('暂无工资明细')
          else
            ..._salaryDetailList.map((item) => _salaryDetailItem(item)),
        ],
      ),
    );
  }

  Widget _salaryDetailItem(SalaryDetailVo item) {
    return GestureDetector(
      onTap: () {
        if (item.id != null) {
          context.push('/approval/salary-detail?id=${item.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.separatorNonOpaque, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.employeeName ?? '未填写姓名',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    children: [
                      _miniLabel('工资'),
                      _miniValue('\u00A5${formatAmount(item.basicSalary)}'),
                      Text(
                        '|',
                        style: TextStyle(
                          color: AppColors.separatorNonOpaque,
                          fontSize: 13,
                        ),
                      ),
                      _miniLabel('扣款'),
                      _miniValue('\u00A5${formatAmount(item.totalDeduction)}'),
                      Text(
                        '|',
                        style: TextStyle(
                          color: AppColors.separatorNonOpaque,
                          fontSize: 13,
                        ),
                      ),
                      _miniLabel('实发'),
                      Text(
                        '\u00A5${formatAmount(item.actualSalary)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '\u203A',
              style: TextStyle(fontSize: 16, color: AppColors.textQuaternary),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 报销卡片 ==========
  Widget _buildReimbursementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('报销申请信息'),
          _infoRow('部门', _reimbursementData?.departmentName ?? '-'),
          _infoRow('申请人', _reimbursementData?.applicantName ?? '-'),
          _infoRow('申请日期', _reimbursementData?.applyDate ?? '-'),
          _infoRow('报销项目', _reimbursementData?.reimbursementProjectName ?? '-'),
          _infoRow(
            '总金额',
            '\u00A5${formatAmount(_reimbursementData?.totalAmount)}',
            isAmount: true,
          ),

          // 报销明细
          _detailSectionHeader('报销明细'),
          if (_reimbursementDetailList.isEmpty)
            _emptyDetail('暂无报销明细')
          else
            ..._reimbursementDetailList.map(
              (item) => _reimbursementDetailItem(item),
            ),
        ],
      ),
    );
  }

  Widget _reimbursementDetailItem(ReimbursementDetailVo item) {
    final urls = parseAttachmentUrls(item.reimbursementProof);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.separatorNonOpaque, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: urls.isNotEmpty ? () => _previewImages(urls) : null,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.separatorNonOpaque,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: urls.isNotEmpty
                  ? Image.network(
                      urls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderCircle('票'),
                    )
                  : _placeholderCircle('票'),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.reimbursementDetail ?? '未填写明细内容',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '\u00A5${formatAmount(item.reimbursementAmount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 公共辅助 ==========
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.separatorNonOpaque, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ),
  );

  Widget _infoRow(String label, String value, {bool isAmount = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isAmount ? 18 : 14,
                  fontWeight: isAmount ? FontWeight.w600 : FontWeight.normal,
                  color: isAmount ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _detailSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Text(
      title,
      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
  );

  /// 上下布局的字段标签
  Widget _verticalFieldLabel(String label) => Text(
    label,
    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
  );

  /// 上下布局的字段（标签在上，值在下）
  Widget _verticalField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _verticalFieldLabel(label),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    ],
  );

  Widget _emptyDetail(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
    ),
  );

  Widget _placeholderCircle(String text) => Center(
    child: Text(
      text,
      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
  );

  Widget _miniLabel(String text) =>
      Text(text, style: TextStyle(fontSize: 13, color: AppColors.textTertiary));

  Widget _miniValue(String text) =>
      Text(text, style: TextStyle(fontSize: 13, color: AppColors.textPrimary));

  void _previewImages(List<String> urls) {
    // TODO: 实现图片预览（全屏 PageView）
  }
}
