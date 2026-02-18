/// API 常量
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://8.140.98.157:8080';
  static const String ossUrl = 'http://8.140.98.157:8080';
  static const String clientId = 'oa_personnel_client';
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // WebSocket
  static const String wsBaseUrl = 'ws://8.140.98.157:8080';
  static const String wsPath = '/resource/websocket';

  /// 固定审批人 ID 列表 - 对应后端 ApprovalFlowHelper.FIXED_APPROVER_IDS
  static const List<int> fixedApproverIds = [121, 118, 119, 120];

  // ========== 审批人 ID 常量 ==========
  static const int approverDengPeipei = 121;
  static const int approverGuo = 118;
  static const int approverWang = 119;
  static const int approverSunLin = 120; // 财务/最终审批人
}
