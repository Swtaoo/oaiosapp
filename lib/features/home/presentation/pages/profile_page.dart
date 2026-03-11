import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/app_update/app_update_service.dart';
import '../../../../services/app_update/update_dialog.dart';
import '../../../auth/providers/auth_provider.dart';

/// 当前版本号 Provider（只读取一次）
final _currentVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// 个人中心页面 - 对应 src/pages/me/me.vue
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(currentUserProvider);
    final nickname = userInfo?.displayName ?? '用户';
    final phone = userInfo?.phone ?? '';
    final updateState = ref.watch(appUpdateProvider);
    final currentVersion = ref.watch(_currentVersionProvider);
    final isChecking = updateState.status == UpdateStatus.checking;
    final hasNewVersion = updateState.hasNewVersion;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部个人信息卡
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: GestureDetector(
                onTap: () => context.push('/me/changeInfo'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.neutral200,
                        child: const Icon(Icons.person, size: 32, color: AppColors.neutral400),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 菜单分组 1: 个人信息 + 修改密码
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: '个人信息',
                  onTap: () => context.push('/me/changeInfo'),
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: '修改密码',
                  isLast: true,
                  onTap: () => context.push('/me/changePassword'),
                ),
              ],
            ),

            // 菜单分组 2: 检查更新
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.system_update_outlined,
                  label: '检查更新',
                  isLast: true,
                  trailing: _buildVersionTrailing(
                    currentVersion: currentVersion.valueOrNull ?? '',
                    isChecking: isChecking,
                    hasNewVersion: hasNewVersion,
                    newVersion: updateState.versionInfo?.versionName ?? '',
                  ),
                  onTap: isChecking ? null : () => _handleCheckUpdate(context, ref),
                ),
              ],
            ),

            // 退出登录
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: GestureDetector(
                onTap: () => _handleLogout(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  /// 版本行右侧内容
  Widget _buildVersionTrailing({
    required String currentVersion,
    required bool isChecking,
    required bool hasNewVersion,
    required String newVersion,
  }) {
    if (isChecking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Text('检查中', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
    }

    if (hasNewVersion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '新版本 v$newVersion',
                  style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (currentVersion.isNotEmpty) {
      return Text(
        'v$currentVersion',
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleCheckUpdate(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appUpdateProvider.notifier);
    final info = await notifier.checkUpdate();
    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      showUpdateDialog(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前已是最新版本'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(children: items),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isLast = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppColors.separatorNonOpaque,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
