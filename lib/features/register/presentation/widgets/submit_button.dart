import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 注册模块底部提交按钮 — 白底 + 顶部分隔线 + SafeArea + 触感反馈
class SubmitButton extends StatelessWidget {
  final String label;
  final bool isSubmitting;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const SubmitButton({
    super.key,
    this.label = '下一步',
    this.isSubmitting = false,
    this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: const Border(
          top: BorderSide(color: AppColors.neutral200, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.s12,
            AppSpacing.pagePadding,
            AppSpacing.s12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPressed?.call();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveBg,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: effectiveBg.withValues(alpha: 0.45),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isSubmitting
                      ? Row(
                          key: const ValueKey('loading'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              '提交中...',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          key: const ValueKey('label'),
                          label,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
