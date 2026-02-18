// 工作汇报 API
import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/work_report_models.dart';

class WorkReportApi {
  final Dio _dio;

  WorkReportApi(this._dio);

  /// 获取工作汇报列表
  /// GET /oa/workReport/list
  Future<PaginatedResponse<WorkReportVo>> getList({
    String? period,
    String? title,
    int pageNum = 1,
    int pageSize = 200,
  }) async {
    final response = await _dio.get(
      '/oa/workReport/list',
      queryParameters: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'period': ?period,
        'title': ?title,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => WorkReportVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取工作汇报详情
  /// GET /oa/workReport/{id}
  Future<ApiResponse<WorkReportVo>> getDetail(int id) async {
    final response = await _dio.get('/oa/workReport/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => WorkReportVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增工作汇报
  /// POST /oa/workReport
  Future<ApiResponse<void>> create(WorkReportSubmit data) async {
    final response = await _dio.post(
      '/oa/workReport',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }
}
