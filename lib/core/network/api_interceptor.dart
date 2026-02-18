import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../router/app_router.dart';

/// API 拦截器 - 对应 src/http/interceptor.ts
///
/// 使用 QueuedInterceptor 确保 async token 读取完成后再发请求。
/// 基础 Interceptor 的 async void onRequest 会导致 token 注入竞态。
///
/// 职责:
/// 1. 注入 Authorization: Bearer {token}
/// 2. 注入 clientid: oa_personnel_client
/// 3. 401 → 清除 token → 跳转登录页
class ApiInterceptor extends QueuedInterceptor {
  final Ref _ref;

  ApiInterceptor(this._ref);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // 注入 token
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // 注入 clientid
      options.headers['clientid'] = ApiConstants.clientId;
    } catch (e) {
      debugPrint('[ApiInterceptor] onRequest error: $e');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 ||
        err.response?.data is Map &&
            (err.response?.data as Map)['code'] == 401) {
      debugPrint('[ApiInterceptor] 401 detected, clearing token');
      // 清除 token 并跳转登录页
      final storage = _ref.read(secureStorageProvider);
      await storage.clearAll();

      // 使用 GoRouter 跳转登录
      final router = _ref.read(goRouterProvider);
      router.go('/login');
    }
    handler.next(err);
  }
}
