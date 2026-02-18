// 规章制度 API - 对应 src/api/regulation.ts

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/regulation_models.dart';

class RegulationApi {
  final Dio _dio;

  RegulationApi(this._dio);

  /// 获取规章制度列表
  /// GET /oa/companyRegulation/list
  Future<PaginatedResponse<RegulationVo>> getList({
    int? regulationType,
    String? fileName,
    String? isAsc,
    int? pageNum,
    int? pageSize,
  }) async {
    final response = await _dio.get(
      '/oa/companyRegulation/list',
      queryParameters: {
        'regulationType': ?regulationType,
        'fileName': ?fileName,
        'isAsc': ?isAsc,
        'pageNum': ?pageNum,
        'pageSize': ?pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => RegulationVo.fromJson(json as Map<String, dynamic>),
    );
  }
}
