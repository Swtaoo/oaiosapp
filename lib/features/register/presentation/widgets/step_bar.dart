// 步骤条组件 - 对应 src/components/StepBar.vue

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 全宽沉浸式步骤条 — 贴顶、无卡片容器、与 AppBar 视觉连续
class StepBar extends StatelessWidget {
  final int current; // 1-based current step
  final List<String> steps;

  const StepBar({super.key, required this.current, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundPrimary,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s16,
        AppSpacing.pagePadding,
        AppSpacing.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isActive = stepNum == current;
          final isCompleted = stepNum < current;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 节点 + 连接线
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 左侧连接线（第一个 step 用透明占位保持圆圈居中）
                    if (index > 0)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.neutral200,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    // 节点圆圈
                    _StepNode(
                      stepNum: stepNum,
                      isActive: isActive,
                      isCompleted: isCompleted,
                    ),
                    // 右侧连接线（最后一个 step 用透明占位保持圆圈居中）
                    if (index < steps.length - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.neutral200,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: AppSpacing.s6),
                // 步骤标签
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.caption1.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.neutral500
                            : AppColors.neutral400,
                  ),
                  child: Text(steps[index], textAlign: TextAlign.center),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final int stepNum;
  final bool isActive;
  final bool isCompleted;

  const _StepNode({
    required this.stepNum,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? AppColors.primary
            : isActive
                ? AppColors.primary
                : AppColors.neutral100,
        border: isActive
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 3)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : isActive
                ? Text(
                    '$stepNum',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '$stepNum',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral400,
                    ),
                  ),
      ),
    );
  }
}
