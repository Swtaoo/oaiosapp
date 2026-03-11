import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

/// API 拦截器 - 对应 src/http/interceptor.ts
///
/// 职责:
/// 1. 注入 Authorization: Bearer {token}
/// 2. 注入 clientid: oa_personnel_client
/// 3. 认证失败(401/token冻结/过期) → 清除状态 → 跳转登录页
class ApiInterceptor extends Interceptor {
  final Ref _ref;

  /// 防止多个并发请求同时触发 logout
  bool _isLoggingOut = false;

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
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    // 检查 HTTP 200 但 body code 表示认证失败的情况
    final data = response.data;
    if (data is Map && _isAuthErrorCode(data['code'])) {
      debugPrint('[ApiInterceptor] Auth error in response body: code=${data['code']}, msg=${data['msg']}');
      await _forceLogout();
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final bodyCode = data is Map ? data['code'] : null;

    if (statusCode == 401 || _isAuthErrorCode(bodyCode)) {
      debugPrint('[ApiInterceptor] Auth failure detected: '
          'httpStatus=$statusCode, bodyCode=$bodyCode');
      await _forceLogout();
    }
    handler.next(err);
  }

  /// 判断响应 code 是否为认证失败
  bool _isAuthErrorCode(dynamic code) {
    if (code == null) return false;
    final intCode = code is int ? code : int.tryParse(code.toString());
    if (intCode == null) return false;
    return intCode == 401;
  }

  /// 强制登出: 清除存储 + 重置内存状态 + 跳转登录页
  Future<void> _forceLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // 1. 清除本地存储
      final storage = _ref.read(secureStorageProvider);
      await storage.clearAll();

      // 2. 重置内存中的认证状态 (关键: 否则 GoRouter redirect 仍认为已登录)
      _ref.read(authStateNotifierProvider.notifier).forceLogout();

      // 3. 跳转登录页
      final router = _ref.read(goRouterProvider);
      router.go('/login');
    } catch (e) {
      debugPrint('[ApiInterceptor] _forceLogout error: $e');
    } finally {
      _isLoggingOut = false;
    }
  }
}
