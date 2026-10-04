import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  static const RoundedRectangleBorder _square = RoundedRectangleBorder();

  static TextTheme _textTheme(Color ink, Color muted) => TextTheme(
    displayLarge: AppTypography.displayHero.copyWith(color: ink),
    displayMedium: AppTypography.h1.copyWith(color: ink),
    displaySmall: AppTypography.h2.copyWith(color: ink),
    headlineLarge: AppTypography.h1.copyWith(color: ink),
    headlineMedium: AppTypography.h2.copyWith(color: ink),
    headlineSmall: AppTypography.h3.copyWith(color: ink),
    titleLarge: AppTypography.h2.copyWith(color: ink),
    titleMedium: AppTypography.h3.copyWith(color: ink),
    titleSmall: AppTypography.labelLarge.copyWith(color: ink),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: ink),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: ink),
    bodySmall: AppTypography.bodySmall.copyWith(color: muted),
    labelLarge: AppTypography.labelLarge.copyWith(color: ink),
    labelMedium: AppTypography.labelSmall.copyWith(color: ink),
    labelSmall: AppTypography.labelSmall.copyWith(color: muted),
  );

  static ThemeData _base(ColorScheme scheme, SystemUiOverlayStyle overlay) {
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      pageTransitionsTheme: pageTransitionsTheme,
      textTheme: _textTheme(ink, muted),
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlay,
        titleTextStyle: AppTypography.h3.copyWith(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: muted),
        hintStyle: AppTypography.bodyMedium.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: _square,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primaryContainer),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimaryContainer),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _square,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: _square,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: scheme.onInverseSurface,
        ),
        elevation: 0,
        shape: _square,
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _square,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(_square),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: AppColors.primaryContainer,
        shape: _square,
        side: BorderSide(color: scheme.outline),
        labelStyle: AppTypography.labelLarge.copyWith(color: ink),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface),
        textStyle: AppTypography.bodySmall.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: _square,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: _square,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.onPrimary,
            );
          }
          return AppTypography.labelSmall.copyWith(color: ink);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onPrimary);
          }
          return IconThemeData(color: ink);
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: _square,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryContainer,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSurface,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.white,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.primaryContainer,
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppColors.primaryForeground,
    onPrimary: AppColors.onSurface,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.surfaceContainerDark,
    onSecondaryContainer: AppColors.onSurfaceDark,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onSurfaceDark,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.error,
    onSurface: AppColors.onSurfaceDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
    surfaceContainerLow: AppColors.surfaceContainerLowDark,
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    inverseSurface: AppColors.surfaceContainerLowest,
    onInverseSurface: AppColors.onSurface,
    inversePrimary: AppColors.primary,
  );

  static ThemeData get light => _base(
    _lightScheme,
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  static ThemeData get dark => _base(
    _darkScheme,
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}
