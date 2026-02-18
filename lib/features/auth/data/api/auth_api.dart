import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../../../../core/network/api_response.dart';

/// 认证 API - 对应 src/api/login.ts
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// 用户登录
  /// POST /oa/auth/login
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final response = await _dio.post(
      '/oa/auth/login',
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取用户信息
  /// GET /oa/auth/getInfo
  Future<ApiResponse<UserInfo>> getUserInfo() async {
    final response = await _dio.get('/oa/auth/getInfo');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => UserInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 退出登录
  /// POST /oa/auth/logout
  Future<void> logout() async {
    await _dio.post('/oa/auth/logout');
  }

  /// 修改密码
  /// PUT /oa/auth/updatePwd
  Future<ApiResponse<void>> updatePassword(UpdatePasswordRequest request) async {
    final response = await _dio.put(
      '/oa/auth/updatePwd',
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }
}
