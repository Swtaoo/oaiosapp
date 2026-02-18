import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/approval_models.dart';

/// 审批 API - 对应 src/service/approvalFlow.ts + fundApplication.ts + reimbursement.ts + salaryInfo.ts + salaryDetail.ts
class ApprovalApi {
  final Dio _dio;

  ApprovalApi(this._dio);

  // ========== 审批流程 ==========

  /// 查询我的待审批列表
  /// GET /oa/approvalFlow/myPending
  Future<PaginatedResponse<ApprovalFlowVo>> getMyPending({
    String? filterType, // myPending/pending/approved/paid
    String? applicantName,
    int pageNum = 1,
    int pageSize = 10,
    String orderByColumn = 'createTime',
    String isAsc = 'desc',
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNum': pageNum,
      'pageSize': pageSize,
      'orderByColumn': orderByColumn,
      'isAsc': isAsc,
    };
    if (filterType != null && filterType.isNotEmpty) {
      queryParameters['filterType'] = filterType;
    }
    if (applicantName != null && applicantName.isNotEmpty) {
      queryParameters['applicantName'] = applicantName;
    }
    final response = await _dio.get(
      '/oa/approvalFlow/myPending',
      queryParameters: queryParameters,
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ApprovalFlowVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 查询审批流程列表（按 objectId + type 筛选）
  /// GET /oa/approvalFlow/list
  Future<PaginatedResponse<ApprovalFlowVo>> getApprovalFlowList({
    required String approvalObjectType,
    required int objectId,
    int pageNum = 1,
    int pageSize = 100,
    String orderByColumn = 'createTime',
    String isAsc = 'asc',
  }) async {
    final response = await _dio.get(
      '/oa/approvalFlow/list',
      queryParameters: {
        'approvalObjectType': approvalObjectType,
        'objectId': objectId,
        'pageNum': pageNum,
        'pageSize': pageSize,
        'orderByColumn': orderByColumn,
        'isAsc': isAsc,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ApprovalFlowVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 审批操作（通过/驳回）- 更新已有审批流程节点
  /// PUT /oa/approvalFlow（需要 id）
  Future<ApiResponse<void>> submitApproval(ApprovalFlowSubmit data) async {
    final response = await _dio.put(
      '/oa/approvalFlow',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 创建固定审批流程（新建资金申请后调用）
  /// POST /oa/approvalFlow/createFixed
  Future<ApiResponse<void>> createFixedApprovalFlow({
    required String approvalObjectType,
    required int objectId,
  }) async {
    final response = await _dio.post(
      '/oa/approvalFlow/createFixed',
      queryParameters: {
        'approvalObjectType': approvalObjectType,
        'objectId': objectId,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== 资金申请 ==========

  /// 获取资金申请详情
  /// GET /oa/fundApplication/{id}
  Future<ApiResponse<FundApplicationVo>> getFundApplication(int id) async {
    final response = await _dio.get('/oa/fundApplication/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => FundApplicationVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增资金申请
  /// POST /oa/fundApplication
  Future<ApiResponse<void>> createFundApplication(
      FundApplicationSubmit data) async {
    final response = await _dio.post(
      '/oa/fundApplication',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 获取资金申请明细列表
  /// GET /oa/fundApplicationDetail/list
  Future<PaginatedResponse<FundApplicationDetailVo>>
      getFundApplicationDetailList({
    required int fundApplicationId,
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/fundApplicationDetail/list',
      queryParameters: {
        'fundApplicationId': fundApplicationId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) =>
          FundApplicationDetailVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 上传支付凭证
  /// PUT /oa/fundApplication/paymentVoucher/{id}
  Future<ApiResponse<void>> updatePaymentVoucher({
    required int id,
    required String paymentVoucher,
  }) async {
    final response = await _dio.put(
      '/oa/fundApplication/paymentVoucher/$id',
      data: {'paymentVoucher': paymentVoucher},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== 报销 ==========

  /// 获取报销详情
  /// GET /oa/reimbursement/{id}
  Future<ApiResponse<ReimbursementVo>> getReimbursement(int id) async {
    final response = await _dio.get('/oa/reimbursement/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ReimbursementVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取报销明细列表
  /// GET /oa/reimbursementDetail/list
  Future<PaginatedResponse<ReimbursementDetailVo>> getReimbursementDetailList({
    required int reimbursementId,
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/reimbursementDetail/list',
      queryParameters: {
        'reimbursementId': reimbursementId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) =>
          ReimbursementDetailVo.fromJson(json as Map<String, dynamic>),
    );
  }

  // ========== 工资 ==========

  /// 获取工资信息详情
  /// GET /oa/salaryInfo/{id}
  Future<ApiResponse<SalaryInfoVo>> getSalaryInfo(int id) async {
    final response = await _dio.get('/oa/salaryInfo/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => SalaryInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取工资明细列表
  /// GET /oa/salaryDetail/list
  Future<PaginatedResponse<SalaryDetailVo>> getSalaryDetailList({
    required int salaryId,
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/salaryDetail/list',
      queryParameters: {
        'salaryId': salaryId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => SalaryDetailVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取工资明细详情
  /// GET /oa/salaryDetail/{id}
  Future<ApiResponse<SalaryDetailVo>> getSalaryDetail(int id) async {
    final response = await _dio.get('/oa/salaryDetail/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => SalaryDetailVo.fromJson(json as Map<String, dynamic>),
    );
  }

  // ========== 人员 ==========

  /// 获取人员列表（用于下一审批人选择）
  /// GET /oa/personnelBasicInfo/list
  Future<PaginatedResponse<PersonnelBasicInfoVo>> getPersonnelList({
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/personnelBasicInfo/list',
      queryParameters: {
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelBasicInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }
}
