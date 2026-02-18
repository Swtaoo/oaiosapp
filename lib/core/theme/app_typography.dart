import 'package:flutter/material.dart';

/// 字体层级系统 - 对应 src/styles/design-tokens/typography.ts
/// 基于 SF Pro 字体规范
class AppTypography {
  AppTypography._();

  // Large Title - 页面主标题
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 41 / 34,
    letterSpacing: 0.36,
    fontWeight: FontWeight.w700,
  );

  // Title 1
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: 0.36,
    fontWeight: FontWeight.w700,
  );

  // Title 2
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0.36,
    fontWeight: FontWeight.w700,
  );

  // Title 3
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    height: 25 / 20,
    letterSpacing: 0.36,
    fontWeight: FontWeight.w600,
  );

  // Headline
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: -0.41,
    fontWeight: FontWeight.w600,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: -0.41,
    fontWeight: FontWeight.w400,
  );

  // Callout
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 21 / 16,
    letterSpacing: -0.32,
    fontWeight: FontWeight.w400,
  );

  // Subheadline
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w400,
  );

  // Footnote
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: -0.08,
    fontWeight: FontWeight.w400,
  );

  // Caption 1
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  // Caption 2
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    letterSpacing: 0.06,
    fontWeight: FontWeight.w400,
  );

  // Form Field - 表单字段专用 (14px)
  static const TextStyle formField = TextStyle(
    fontSize: 14,
    height: 19 / 14,
    letterSpacing: -0.15,
    fontWeight: FontWeight.w400,
  );

  // Form Field Semibold
  static const TextStyle formFieldSemibold = TextStyle(
    fontSize: 14,
    height: 19 / 14,
    letterSpacing: -0.15,
    fontWeight: FontWeight.w600,
  );
}
