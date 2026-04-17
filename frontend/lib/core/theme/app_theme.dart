import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Main app theme configuration - Digital Brutalist Design System
class AppTheme {
  AppTheme._();

  // ─── Spacing ──────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ─── Brutalist Border Radius - ALL ZERO ─────────────────
  static const double radiusNone = 0;
  static const BorderRadius borderRadiusZero = BorderRadius.zero;

  @Deprecated('Use BorderRadius.zero instead')
  static BorderRadius get inputBorderRadius => borderRadiusZero;
  @Deprecated('Use BorderRadius.zero instead')
  static BorderRadius get cardBorderRadius => borderRadiusZero;
  @Deprecated('Use BorderRadius.zero instead')
  static BorderRadius get chipBorderRadius => borderRadiusZero;

  // ─── Animation Duration ────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);

  // ─── Light Theme ──────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSurface,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.white,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.white,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.primaryContainer,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceContainerLowest,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.outline),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.outline),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingMd,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceContainerLowest,
          shape: const RoundedRectangleBorder(
            borderRadius: borderRadiusZero,
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceContainerLowest,
          indicatorColor: AppColors.primaryContainer,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: AppColors.onSurface,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.white);
            }
            return const IconThemeData(color: AppColors.onSurface);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          thickness: 0,
          space: 0,
        ),
        splashFactory: InkRipple.splashFactory,
      );

  // ─── Dark Theme ───────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        brightness: Brightness.dark,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryContainer,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primary,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.surfaceContainerDark,
          onSecondaryContainer: AppColors.inverseOnSurface,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.white,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.inverseOnSurface,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.inverseOnSurface,
          onSurfaceVariant: AppColors.inverseOnSurface,
          outline: AppColors.outlineVariant,
          outlineVariant: AppColors.outline,
          inverseSurface: AppColors.surfaceContainerLowest,
          onInverseSurface: AppColors.onSurface,
          inversePrimary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.inverseOnSurface,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerDark,
          border: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: borderRadiusZero,
            borderSide: BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: AppColors.inverseOnSurface),
          hintStyle:
              TextStyle(color: AppColors.inverseOnSurface.withAlpha(178)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingMd,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceContainerDark,
          shape: const RoundedRectangleBorder(
            borderRadius: borderRadiusZero,
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          indicatorColor: AppColors.primaryContainer,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: AppColors.inverseOnSurface,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.onPrimary);
            }
            return const IconThemeData(color: AppColors.inverseOnSurface);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          thickness: 0,
          space: 0,
        ),
        splashFactory: InkRipple.splashFactory,
      );
}
