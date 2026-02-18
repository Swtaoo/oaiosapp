import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/approval_models.dart';

/// 格式化时间线时间 (yyyy.MM.dd HH:mm)
String formatTimelineTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  } catch (e) { debugPrint('[approval_utils] Error: $e');
    return dateStr;
  }
}

/// 格式化金额为两位小数
String formatAmount(dynamic value) {
  if (value == null) return '0.00';
  if (value is String) {
    if (value.isEmpty) return '0.00';
    final num = double.tryParse(value);
    return num == null ? '0.00' : num.toStringAsFixed(2);
  }
  if (value is num) return value.toStringAsFixed(2);
  return '0.00';
}

/// 解析附件字符串为 URL 列表
/// 支持逗号分隔，支持 url|fileName 格式
List<String> parseAttachmentUrls(String? attachmentStr) {
  if (attachmentStr == null || attachmentStr.isEmpty) return [];
  return attachmentStr
      .split(',')
      .map((item) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) return '';
        // 支持 url|fileName 格式
        final url = trimmed.split('|').first.trim();
        if (url.isEmpty) return '';
        // 相对路径拼接 baseUrl
        if (url.startsWith('/') && !url.startsWith('//')) {
          return '${ApiConstants.baseUrl}$url';
        }
        return url;
      })
      .where((url) => url.isNotEmpty)
      .toList();
}

/// 判断是否为图片文件
bool isImageFile(String url) {
  const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  final lower = url.toLowerCase();
  return imageExts.any((ext) => lower.contains(ext));
}

/// 判断是否为 PDF 文件
bool isPdfFile(String url) {
  return url.toLowerCase().contains('.pdf');
}

/// 获取审批状态文本（原始 status 字段: 0/1/2）
String getStatusText(String? status) {
  if (status == null || status.isEmpty) return '待审批';
  const map = {
    '0': '待审批',
    '1': '已通过',
    '2': '已驳回',
    'pending': '待审批',
    'approved': '已通过',
    'rejected': '已驳回',
    '待审批': '待审批',
    '已通过': '已通过',
    '已驳回': '已驳回',
  };
  return map[status] ?? status;
}

/// 获取 displayStatus 对应的中文文本
String getDisplayStatusText(String? displayStatus) {
  if (displayStatus == null || displayStatus.isEmpty) return '待审批';
  const map = {
    'myPending': '待我审批',
    'pending': '待审批',
    'approved': '已审批',
    'paid': '已支付',
  };
  return map[displayStatus] ?? displayStatus;
}

/// iOS 紫色 - 用于已支付状态
const Color _iosPurple = Color(0xFFAF52DE);

/// 获取 displayStatus 对应的文本颜色
Color getDisplayStatusColor(String? displayStatus) {
  switch (displayStatus) {
    case 'myPending':
      return AppColors.error;
    case 'pending':
      return AppColors.warning;
    case 'approved':
      return AppColors.success;
    case 'paid':
      return _iosPurple;
    default:
      return AppColors.textTertiary;
  }
}

/// 获取 displayStatus 对应的背景颜色
Color getDisplayStatusBgColor(String? displayStatus) {
  switch (displayStatus) {
    case 'myPending':
      return AppColors.error.withValues(alpha: 0.1);
    case 'pending':
      return AppColors.warning.withValues(alpha: 0.1);
    case 'approved':
      return AppColors.success.withValues(alpha: 0.1);
    case 'paid':
      return _iosPurple.withValues(alpha: 0.1);
    default:
      return Colors.grey.withValues(alpha: 0.1);
  }
}

/// 推断 displayStatus（后端未返回时的前端兜底）
///
/// 优先使用后端返回的 displayStatus，为空时根据节点信息推断：
/// - approverId == currentUserId 且 status 待审批 → myPending
/// - 上一节点已通过且 nextApproverId == currentUserId → myPending
/// - status 已通过/已驳回 → approved
/// - status 待审批但不是当前用户 → pending
String inferDisplayStatus(ApprovalFlowVo item, int currentUserId) {
  // 后端已返回，直接使用
  if (item.displayStatus != null && item.displayStatus!.isNotEmpty) {
    return item.displayStatus!;
  }

  // 前端兜底推断
  final status = item.status;

  // Case 1: 当前用户是该节点的审批人，且节点待审批
  if (item.approverId == currentUserId &&
      (status == '0' || status == null || status.isEmpty)) {
    return 'myPending';
  }

  // Case 2: 上一节点已通过，nextApproverId 指向当前用户 → 轮到当前用户
  if (item.nextApproverId == currentUserId &&
      (status == '1' || status == 'approved')) {
    return 'myPending';
  }

  // Case 3: 节点待审批，nextApproverId 指向当前用户（申请人节点后轮到当前用户）
  if (item.nextApproverId == currentUserId &&
      (status == '0' || status == null || status.isEmpty)) {
    return 'myPending';
  }

  // 节点已通过
  if (status == '1' || status == 'approved') {
    return 'approved';
  }

  // 节点已驳回
  if (status == '2' || status == 'rejected') {
    return 'approved';
  }

  // 节点待审批但不是当前用户
  return 'pending';
}

/// 获取审批类型文本
String getApprovalTypeText(String? type) {
  if (type == null || type.isEmpty) return '审批流程';
  const map = {
    '1': '资金申请',
    '2': '工资申请',
    '3': '报销申请',
  };
  return map[type] ?? type;
}

/// 获取头像显示文本
String getAvatarText(String? name) {
  if (name == null || name.isEmpty) return '?';
  return name[0];
}

/// 格式化日期 (M-d)
String formatShortDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.month}-${date.day}';
  } catch (e) { debugPrint('[approval_utils] Error: $e');
    return dateStr;
  }
}

/// 格式化完整日期 (yyyy-MM-dd)
String formatFullDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd').format(date);
  } catch (e) { debugPrint('[approval_utils] Error: $e');
    return dateStr;
  }
}

/// 格式化完整日期时间，精确到秒 (yyyy-MM-dd HH:mm:ss)
String formatDateTimeFull(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  } catch (e) { debugPrint('[approval_utils] Error: $e');
    return dateStr;
  }
}
