import 'package:flutter/material.dart';
import 'app_colors.dart';

extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get bgColor =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  Color get surfaceColor =>
      isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest;

  Color get surfaceMidColor =>
      isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainer;

  Color get textPrimary => isDark ? AppColors.white : AppColors.darkGray;

  Color get textSecondary => AppColors.mediumGray;

  Color get borderColor =>
      isDark ? AppColors.outlineVariant : AppColors.outline;

  Color get appBarColor =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceContainerLowest;
}
