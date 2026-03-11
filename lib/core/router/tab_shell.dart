import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../../services/app_update/app_update_service.dart';
import '../../../services/app_update/update_dialog.dart';

/// 5-Tab Shell - 对应 tabbar/config.ts
/// Tabs: 首页 / 工作台 / AI助手 / 学习空间 / 我的
class TabShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const TabShell({super.key, required this.navigationShell});

  @override
  ConsumerState<TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<TabShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
  }

  Future<void> _checkAppUpdate() async {
    debugPrint('[TabShell] _checkAppUpdate started');
    try {
      final notifier = ref.read(appUpdateProvider.notifier);
      final info = await notifier.checkUpdate();
      debugPrint(
        '[TabShell] checkUpdate result: hasUpdate=${info?.hasUpdate}, version=${info?.versionName}',
      );

      if (info == null || !info.hasUpdate || !mounted) return;

      final shouldSkip = await notifier.shouldSkipAutoPopup();
      debugPrint('[TabShell] shouldSkipAutoPopup=$shouldSkip');
      if (!mounted || shouldSkip) return;

      debugPrint('[TabShell] showing update dialog');
      showUpdateDialog(context, info);
    } catch (e, stack) {
      debugPrint('[TabShell] _checkAppUpdate error: $e');
      debugPrint('[TabShell] stack: $stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomNavigation(bottomInset: bottomInset),
    );
  }

  Widget _buildBottomNavigation({required double bottomInset}) {
    return SizedBox(
      height: AppSpacing.s64 + AppSpacing.s8 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: AppSpacing.s12,
            right: AppSpacing.s12,
            bottom: AppSpacing.s8,
            child: PhysicalShape(
              color: AppColors.backgroundPrimary,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.10),
              clipBehavior: Clip.antiAlias,
              clipper: const _BottomNavBarClipper(
                borderRadius: 26,
                notchRadius: 30,
                notchCenterY: 0,
              ),
              child: SizedBox(
                height: AppSpacing.s56 + bottomInset,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s8 + bottomInset,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          index: 0,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: '首页',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 1,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: '工作台',
                        ),
                      ),
                      const SizedBox(width: 76),
                      Expanded(
                        child: _buildNavItem(
                          index: 3,
                          icon: Icons.school_outlined,
                          activeIcon: Icons.school,
                          label: '学习空间',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 4,
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: '我的',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _buildCenterAiSlot(bottomInset: bottomInset),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = widget.navigationShell.currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _goToBranch(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s3,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 17,
                  color: selected ? AppColors.primary : AppColors.neutral400,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption2.copyWith(
                  fontSize: 10,
                  height: 1.0,
                  color: selected ? AppColors.primary700 : AppColors.neutral500,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAiSlot({required double bottomInset}) {
    final selected = widget.navigationShell.currentIndex == 2;
    return SizedBox(
      width: 84,
      height: AppSpacing.s64 + bottomInset,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, child: _buildPrimaryAiButton()),
          Positioned(
            bottom: AppSpacing.s10 + bottomInset,
            child: Text(
              'AI助手',
              style: AppTypography.caption2.copyWith(
                color: selected ? AppColors.primary700 : AppColors.neutral500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAiButton() {
    final selected = widget.navigationShell.currentIndex == 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _goToBranch(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: selected ? AppSpacing.s48 : AppSpacing.s44,
          height: selected ? AppSpacing.s48 : AppSpacing.s44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary400, AppColors.primary700],
            ),
            border: Border.all(color: AppColors.backgroundPrimary, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: selected ? 0.24 : 0.16,
                ),
                blurRadius: selected ? 14 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _BottomNavBarClipper extends CustomClipper<Path> {
  final double borderRadius;
  final double notchRadius;
  final double notchCenterY;

  const _BottomNavBarClipper({
    required this.borderRadius,
    required this.notchRadius,
    required this.notchCenterY,
  });

  @override
  Path getClip(Size size) {
    final barPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(borderRadius),
        ),
      );
    final notchPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, notchCenterY),
          radius: notchRadius,
        ),
      );
    return Path.combine(PathOperation.difference, barPath, notchPath);
  }

  @override
  bool shouldReclip(covariant _BottomNavBarClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.notchCenterY != notchCenterY;
  }
}
