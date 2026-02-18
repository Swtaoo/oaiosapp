import 'package:flutter/material.dart';

/// 色彩系统 - 对应 src/styles/design-tokens/colors.ts
/// 基于 iOS HIG 设计规范
class AppColors {
  AppColors._();

  // ========== 主色系统 ==========
  static const Color primary50 = Color(0xFFE5F2FF);
  static const Color primary100 = Color(0xFFCCE5FF);
  static const Color primary200 = Color(0xFF99CCFF);
  static const Color primary300 = Color(0xFF66B2FF);
  static const Color primary400 = Color(0xFF3399FF);
  static const Color primary = Color(0xFF007AFF); // iOS标准蓝
  static const Color primary600 = Color(0xFF0062CC);
  static const Color primary700 = Color(0xFF004999);
  static const Color primary800 = Color(0xFF003166);
  static const Color primary900 = Color(0xFF001933);

  // ========== 灰度系统 ==========
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral950 = Color(0xFF030712);

  // ========== 语义色 ==========
  static const Color success = Color(0xFF34C759); // iOS标准绿
  static const Color warning = Color(0xFFFF9500); // iOS标准橙
  static const Color error = Color(0xFFFF3B30);   // iOS标准红
  static const Color info = Color(0xFF3B82F6);

  // ========== 文本色 ==========
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0x993C3C43); // 60% opacity
  static const Color textTertiary = Color(0x4D3C3C43);  // 30% opacity
  static const Color textQuaternary = Color(0x2E3C3C43);  // 18% opacity
  static const Color textPlaceholder = Color(0x4D3C3C43);

  // ========== 背景色 ==========
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF2F2F7);
  static const Color backgroundTertiary = Color(0xFFFFFFFF);
  static const Color backgroundGroupedPrimary = Color(0xFFF2F2F7);
  static const Color backgroundGroupedSecondary = Color(0xFFFFFFFF);

  // ========== 分隔线 ==========
  static const Color separatorOpaque = Color(0x5C3C3C43);
  static const Color separatorNonOpaque = Color(0xFFC6C6C8);

  // ========== 深色模式 ==========
  static const Color darkPrimary = Color(0xFF0A84FF);
  static const Color darkSuccess = Color(0xFF30D158);
  static const Color darkWarning = Color(0xFFFF9F0A);
  static const Color darkError = Color(0xFFFF453A);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0x99EBEBF5); // 60%
  static const Color darkTextTertiary = Color(0x4DEBEBF5);  // 30%

  static const Color darkBackgroundPrimary = Color(0xFF000000);
  static const Color darkBackgroundSecondary = Color(0xFF1C1C1E);
  static const Color darkBackgroundTertiary = Color(0xFF2C2C2E);

  static const Color darkSeparatorOpaque = Color(0xA6545458);
  static const Color darkSeparatorNonOpaque = Color(0xFF38383A);
}
