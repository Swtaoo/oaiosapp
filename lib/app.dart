import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'services/notification/local_notification_service.dart';
import 'services/notification/notification_service.dart';
import 'services/push/push_service.dart';
import 'services/websocket/websocket_service.dart';

/// App 根组件 - MaterialApp.router + GoRouter
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocalNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 初始化本地通知（不依赖登录状态）
  Future<void> _initLocalNotification() async {
    LocalNotificationNotifier.navigatorKey = rootNavigatorKey;
    await ref.read(localNotificationProvider.notifier).init();
  }

  /// 登录后初始化推送和 WebSocket（并行，互不阻塞）
  Future<void> _initServices() async {
    if (_servicesInitialized) return;
    _servicesInitialized = true;

    // 并行初始化，任一失败不影响另一个
    await Future.wait([
      ref.read(pushServiceProvider.notifier).initPush().catchError((e) {
        debugPrint('[app] initPush error: $e');
      }),
      ref.read(webSocketProvider.notifier).connect().catchError((e) {
        debugPrint('[app] websocket connect error: $e');
      }),
    ]);
  }

  /// 退出登录时清理所有服务
  void _destroyServices() {
    _servicesInitialized = false;
    ref.read(pushServiceProvider.notifier).destroy();
    ref.read(webSocketProvider.notifier).disconnect();
    ref.read(notificationServiceProvider.notifier).clearAllUnread();
    ref.read(localNotificationProvider.notifier).cancelAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(pushServiceProvider.notifier).onEnterForeground();
        break;
      case AppLifecycleState.paused:
        ref.read(pushServiceProvider.notifier).onEnterBackground();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    // 监听登录状态变化
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.valueOrNull?.isLoggedIn ?? false;
      final isLoggedIn = next.valueOrNull?.isLoggedIn ?? false;

      if (!wasLoggedIn && isLoggedIn) {
        // 登录成功
        _initServices();
      } else if (wasLoggedIn && !isLoggedIn) {
        // 退出登录
        _destroyServices();
      }
    });

    // 若首次打开时已登录，也初始化服务
    final isLoggedIn =
        ref.read(authStateProvider).valueOrNull?.isLoggedIn ?? false;
    if (isLoggedIn && !_servicesInitialized) {
      Future.microtask(_initServices);
    }

    return MaterialApp.router(
      title: 'OA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}
