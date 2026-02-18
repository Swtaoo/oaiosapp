/// 路由守卫 - 对应 navigateToInterceptor
///
/// 白名单内的路由不需要登录即可访问
class AuthGuard {
  AuthGuard._();

  /// 白名单路由 - 无需登录
  static const List<String> _whitelist = [
    '/login',
    '/register',
  ];

  /// 判断路由是否在白名单内
  static bool isWhitelisted(String location) {
    return _whitelist.any((path) {
      if (path.endsWith('/')) {
        return location.startsWith(path);
      }
      return location == path || location.startsWith('$path/');
    });
  }
}
