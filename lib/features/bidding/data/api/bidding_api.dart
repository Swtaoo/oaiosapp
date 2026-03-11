// 投标信息 API - 对应后端 OaBiddingController

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/bidding_models.dart';

class BiddingApi {
  final Dio _dio;

  BiddingApi(this._dio);

  /// 获取投标信息列表
  /// GET /oa/bidding/list
  Future<PaginatedResponse<BiddingVo>> getList({
    String? biddingName,
    String? biddingType,
    String? orderByColumn,
    String? isAsc,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/oa/bidding/list',
      queryParameters: {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'biddingName': ?biddingName,
        'biddingType': ?biddingType,
        'orderByColumn': ?orderByColumn,
        'isAsc': ?isAsc,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => BiddingVo.fromJson(json as Map<String, dynamic>),
    );
  }
}
