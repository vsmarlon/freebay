import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Main app theme configuration - Neo-Brutalist Refined Design System
class AppTheme {
  AppTheme._();

  // ─── Spacing ──────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ─── Border Radius – Digital Brutalist (Strict 0px) ───
  static const double radiusNone = 0;
  static const double radiusSmall = 0;
  static const double radiusMedium = 0;
  static const double radiusLarge = 0;
  static const double radiusXl = 0;

  static const BorderRadius borderRadiusZero = BorderRadius.zero;
  static const BorderRadius borderRadiusSmall = BorderRadius.zero;
  static const BorderRadius borderRadiusMedium = BorderRadius.zero;

  // ─── Animation Duration ────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);

  // ─── Page Transitions Theme (Cupertino interactive drag on iOS & Android) ─
  static const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  // ─── Light Theme ──────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        pageTransitionsTheme: pageTransitionsTheme,
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
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outline),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.outline),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentAmber, width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingMd,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
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
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        ),
        splashFactory: InkRipple.splashFactory,
      );

  // ─── Dark Theme ───────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        brightness: Brightness.dark,
        pageTransitionsTheme: pageTransitionsTheme,
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
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(60)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(60)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentAmber, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.inverseOnSurface),
          hintStyle:
              TextStyle(color: AppColors.inverseOnSurface.withAlpha(178)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingMd,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceContainerDark,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
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
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surfaceDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        ),
        splashFactory: InkRipple.splashFactory,
      );
}
