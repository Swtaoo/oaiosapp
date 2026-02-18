import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// 应用主题 - 基于 iOS HIG 色彩系统
class AppTheme {
  AppTheme._();

  // ========== Light Theme ==========
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundSecondary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.separatorNonOpaque,
          thickness: 0.5,
          space: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.neutral200),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.neutral200),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textPlaceholder,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundPrimary,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.neutral400,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTypography.largeTitle,
          displayMedium: AppTypography.title1,
          displaySmall: AppTypography.title2,
          headlineMedium: AppTypography.title3,
          headlineSmall: AppTypography.headline,
          bodyLarge: AppTypography.body,
          bodyMedium: AppTypography.callout,
          bodySmall: AppTypography.subheadline,
          labelLarge: AppTypography.headline,
          labelMedium: AppTypography.footnote,
          labelSmall: AppTypography.caption1,
        ),
      );

  // ========== Dark Theme ==========
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.darkPrimary,
        scaffoldBackgroundColor: AppColors.darkBackgroundPrimary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackgroundPrimary,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkBackgroundSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkSeparatorNonOpaque,
          thickness: 0.5,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkBackgroundSecondary,
          selectedItemColor: AppColors.darkPrimary,
          unselectedItemColor: AppColors.neutral500,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
      );
}
