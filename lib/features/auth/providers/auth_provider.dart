import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/auth_api.dart';
import '../data/models/auth_models.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

/// 认证状态
class AuthState {
  final bool isLoggedIn;
  final UserInfo? userInfo;
  final String? token;

  const AuthState({
    this.isLoggedIn = false,
    this.userInfo,
    this.token,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserInfo? userInfo,
    String? token,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userInfo: userInfo ?? this.userInfo,
        token: token ?? this.token,
      );
}

/// Auth API Provider
final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

/// 认证状态 Provider - 对应 store/token.ts + store/user.ts
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AsyncLoading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.getToken();
      if (token == null || token.isEmpty) {
        state = const AsyncData(AuthState());
        return;
      }

      // 有 token，尝试恢复用户信息
      final userInfoJson = await storage.getUserInfo();
      UserInfo? userInfo;
      if (userInfoJson != null) {
        try {
          userInfo = UserInfo.fromJson(
            jsonDecode(userInfoJson) as Map<String, dynamic>,
          );
        } catch (e) { debugPrint('[auth_provider] Error: $e'); }
      }

      state = AsyncData(AuthState(
        isLoggedIn: true,
        token: token,
        userInfo: userInfo,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 登录
  Future<void> login(LoginRequest request) async {
    final api = _ref.read(authApiProvider);
    final storage = _ref.read(secureStorageProvider);

    // 调用登录 API
    final response = await api.login(request);
    if (!response.isSuccess || response.data == null) {
      throw Exception(response.errorMessage);
    }

    final loginRes = response.data!;
    final token = loginRes.validToken;
    if (token == null || token.isEmpty) {
      throw Exception('登录失败: 未获取到 token');
    }

    // 存储 token
    await storage.setToken(token);

    // 获取用户信息
    final userInfoRes = await api.getUserInfo();
    final userInfo = userInfoRes.data;

    // 存储用户信息
    if (userInfo != null) {
      await storage.setUserInfo(jsonEncode(userInfo.toJson()));
    }

    state = AsyncData(AuthState(
      isLoggedIn: true,
      token: token,
      userInfo: userInfo,
    ));
  }

  /// 获取/刷新用户信息
  Future<UserInfo?> fetchUserInfo() async {
    final api = _ref.read(authApiProvider);
    final storage = _ref.read(secureStorageProvider);

    final res = await api.getUserInfo();
    final userInfo = res.data;
    if (userInfo != null) {
      await storage.setUserInfo(jsonEncode(userInfo.toJson()));
      final current = state.valueOrNull ?? const AuthState();
      state = AsyncData(current.copyWith(userInfo: userInfo));
    }
    return userInfo;
  }

  /// 退出登录
  Future<void> logout() async {
    final api = _ref.read(authApiProvider);
    final storage = _ref.read(secureStorageProvider);

    try {
      await api.logout();
    } catch (e) { debugPrint('[auth_provider] Error: $e');
      // 退出登录 API 失败不影响本地清除
    }

    await storage.clearAll();
    state = const AsyncData(AuthState());
  }

  /// 强制登出 (token 失效/冻结时由拦截器调用，不请求后端)
  void forceLogout() {
    state = const AsyncData(AuthState());
  }
}

/// 认证状态 Notifier Provider
final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  return AuthStateNotifier(ref);
});

/// 便捷别名
final authStateProvider = authStateNotifierProvider;

/// 当前用户信息
final currentUserProvider = Provider<UserInfo?>((ref) {
  return ref.watch(authStateNotifierProvider).valueOrNull?.userInfo;
});

/// 是否管理员 (基于固定审批人 ID 列表)
final isAdminProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserProvider)?.effectiveUserId ?? -1;
  return ApiConstants.fixedApproverIds.contains(userId);
});
