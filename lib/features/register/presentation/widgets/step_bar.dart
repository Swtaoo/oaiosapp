// 步骤条组件 - 对应 src/components/StepBar.vue

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class StepBar extends StatelessWidget {
  final int current; // 1-based current step
  final List<String> steps;

  const StepBar({super.key, required this.current, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s20,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isActive = stepNum == current;
          final isCompleted = stepNum < current;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted || isActive
                              ? AppColors.success
                              : AppColors.neutral200,
                        ),
                      ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : AppColors.neutral200,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  blurRadius: 0,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.backgroundPrimary,
                              )
                            : isActive
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.backgroundPrimary,
                                    ),
                                  )
                                : Text(
                                    '$stepNum',
                                    style: AppTypography.footnote.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutral400,
                                    ),
                                  ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.neutral200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  steps[index],
                  style: AppTypography.caption1.copyWith(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppColors.textPrimary
                        : isCompleted
                            ? AppColors.neutral500
                            : AppColors.neutral400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
