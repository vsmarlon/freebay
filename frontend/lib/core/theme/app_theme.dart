import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

const _cupertinoTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
  },
);

/// Main app theme configuration
class AppTheme {
  AppTheme._();

  // ─── Spacing ──────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ─── Border Radius ────────────────────────────────────
  static const double radiusInput = 8;
  static const double radiusCard = 12;
  static const double radiusChip = 100;

  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(radiusInput);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get chipBorderRadius => BorderRadius.circular(radiusChip);

  // ─── Light Theme ──────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        pageTransitionsTheme: _cupertinoTransitions,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryPurple,
          secondary: AppColors.accentGreen,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkGray,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.h3,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            textStyle: AppTypography.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusCard),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: AppColors.mediumGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: BorderSide(color: AppColors.mediumGray.withAlpha(76)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide:
                const BorderSide(color: AppColors.primaryPurple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm + spacingXs,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: AppColors.darkGray.withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
      );

  // ─── Dark Theme ───────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        brightness: Brightness.dark,
        pageTransitionsTheme: _cupertinoTransitions,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryPurpleLight,
          secondary: AppColors.accentGreenLight,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurpleLight,
            foregroundColor: AppColors.black,
            textStyle: AppTypography.button.copyWith(color: AppColors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusCard),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: spacingLg,
              vertical: spacingMd,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: AppColors.mediumGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: BorderSide(color: AppColors.mediumGray.withAlpha(76)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide:
                const BorderSide(color: AppColors.primaryPurpleLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusInput),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: AppColors.mediumGray),
          hintStyle: TextStyle(color: AppColors.mediumGray.withAlpha(178)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm + spacingXs,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: AppColors.surfaceDark,
          shadowColor: AppColors.black.withAlpha(51),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          indicatorColor: AppColors.primaryPurpleLight.withAlpha(30),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurpleLight,
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: AppColors.mediumGray,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primaryPurpleLight);
            }
            return const IconThemeData(color: AppColors.mediumGray);
          }),
        ),
      );
}
