import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF660062);
  static const Color primaryContainer = Color(0xFF8A1083);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFF9DEE);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);

  static const Color surfaceContainerLowestDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContainerLowDark = Color(0xFF1C1C1C);
  static const Color surfaceContainerDark = Color(0xFF242424);
  static const Color surfaceContainerHighDark = Color(0xFF2E2E2E);
  static const Color surfaceContainerHighestDark = Color(0xFF383838);

  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceVariant = Color(0xFF5F5F5F);
  static const Color onSurfaceDark = Color(0xFFF1F1F1);
  static const Color onSurfaceVariantDark = Color(0xFFA0A0A0);

  static const Color inverseSurface = Color(0xFF303030);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  static const Color outline = Color(0xFF1B1B1B);
  static const Color outlineVariant = Color(0xFFC9C9C9);
  static const Color outlineDark = Color(0xFFF1F1F1);
  static const Color outlineVariantDark = Color(0xFF3A3A3A);

  static const Color secondary = Color(0xFF5E5E5E);
  static const Color secondaryContainer = Color(0xFFE2E2E2);
  static const Color tertiary = Color(0xFF343637);
  static const Color tertiaryContainer = Color(0xFF4B4D4D);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);
  static const Color darkGray = Color(0xFF1F1F1F);
  static const Color mediumGray = Color(0xFF6E6E6E);
  static const Color lightGray = Color(0xFFF3F3F3);
  static const Color backgroundLight = surface;
  static const Color backgroundDark = surfaceDark;

  static const LinearGradient brutalistGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brutalistGradientLight = LinearGradient(
    colors: [primaryContainer, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
