import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';

/// 常用功能（首页快捷入口）API
class QuickActionsApi {
  final Dio _dio;

  QuickActionsApi(this._dio);

  /// 获取当前用户的常用功能 key 列表
  /// GET /oa/quickAction/my
  Future<ApiResponse<List<String>>> getMyQuickActions() async {
    final response = await _dio.get('/oa/quickAction/my');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => (json as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }

  /// 保存当前用户的常用功能 key 列表
  /// PUT /oa/quickAction/my
  Future<ApiResponse<void>> saveMyQuickActions(List<String> keys) async {
    final response = await _dio.put(
      '/oa/quickAction/my',
      data: {
        'keys': keys,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }
}

