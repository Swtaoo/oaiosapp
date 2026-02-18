import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/approval_models.dart';
import '../../data/utils/approval_utils.dart';

/// 审批流程时间线
class ApprovalTimeline extends StatelessWidget {
  final List<ApprovalFlowVo> flowList;

  const ApprovalTimeline({super.key, required this.flowList});

  /// 节点状态：通过/驳回/待审批(当前)/未到达
  _NodeStatus _getNodeStatus(ApprovalFlowVo item, bool isLastNode) {
    if (item.status == '1' || item.status == 'approved') {
      return _NodeStatus.approved;
    }
    if (item.status == '2' || item.status == 'rejected') {
      return _NodeStatus.rejected;
    }
    // status == '0' or null：待审批
    if (isLastNode || item.status == '0') {
      return _NodeStatus.current;
    }
    return _NodeStatus.waiting;
  }

  Color _nodeColor(_NodeStatus status) {
    switch (status) {
      case _NodeStatus.approved:
        return AppColors.success;
      case _NodeStatus.rejected:
        return AppColors.error;
      case _NodeStatus.current:
        return AppColors.warning;
      case _NodeStatus.waiting:
        return AppColors.neutral300;
    }
  }

  String _nodeTypeLabel(int? nodeType) {
    switch (nodeType) {
      case 0:
        return '申请人';
      case 1:
        return '审批人';
      default:
        return '';
    }
  }

  String _statusLabel(_NodeStatus status) {
    switch (status) {
      case _NodeStatus.approved:
        return '已通过';
      case _NodeStatus.rejected:
        return '已驳回';
      case _NodeStatus.current:
        return '待审批';
      case _NodeStatus.waiting:
        return '等待中';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
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
                  '流程',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          if (flowList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  '暂无审批记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                children: List.generate(flowList.length, (index) {
                  final item = flowList[index];
                  final isLast = index == flowList.length - 1;
                  final status = _getNodeStatus(item, isLast);
                  return _buildTimelineItem(item, isLast, status);
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      ApprovalFlowVo item, bool isLast, _NodeStatus status) {
    final color = _nodeColor(status);
    final isCurrent = status == _NodeStatus.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 连接线
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // 头像
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(color: AppColors.warning, width: 2)
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        getAvatarText(item.approverName ??
                            item.approverId?.toString()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // 状态图标
                    if (status == _NodeStatus.approved)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (status == _NodeStatus.rejected)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                // 连接线
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: status == _NodeStatus.approved
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.separatorNonOpaque,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 内容
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 审批人名 + 角色标签 + 状态标签
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.approverName ?? '-',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_nodeTypeLabel(item.nodeType).isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral100,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  _nodeTypeLabel(item.nodeType),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 时间
                  if (item.approvalTime != null || item.createTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatTimelineTime(
                            item.approvalTime ?? item.createTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),

                  // 审批意见
                  if ((item.approvalOpinion?.isNotEmpty ?? false) ||
                      (item.approvalRemark?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.approvalOpinion ?? item.approvalRemark ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeStatus { approved, rejected, current, waiting }
