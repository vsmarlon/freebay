import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  bool get isDark => theme.brightness == Brightness.dark;

  ColorScheme get colors => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  Color get bgColor => colors.surface;

  Color get surfaceColor => colors.surfaceContainerLow;

  Color get surfaceMidColor => colors.surfaceContainer;

  Color get surfaceHighColor => colors.surfaceContainerHigh;

  Color get textPrimary => colors.onSurface;

  Color get textSecondary => colors.onSurfaceVariant;

  Color get borderColor => colors.outline;

  Color get borderSoftColor => colors.outlineVariant;

  Color get appBarColor => colors.surface;
}
