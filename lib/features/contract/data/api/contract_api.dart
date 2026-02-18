// 合同 API - 对应 src/api/contract.ts

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/contract_models.dart';

class ContractApi {
  final Dio _dio;

  ContractApi(this._dio);

  /// 获取合同列表
  /// GET /oa/contract/list
  Future<PaginatedResponse<ContractVo>> getList({
    int? personnelId,
    String? personnelName,
    String? orderByColumn,
    String? isAsc,
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/contract/list',
      queryParameters: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'personnelId': ?personnelId,
        'personnelName': ?personnelName,
        'orderByColumn': ?orderByColumn,
        'isAsc': ?isAsc,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ContractVo.fromJson(json as Map<String, dynamic>),
    );
  }
}
