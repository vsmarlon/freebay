import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tokens for the Digital Brutalist design system.
/// Headlines use Space Grotesk; body/UI text uses Inter.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String headlineFontFamily = 'SpaceGrotesk';

  // ─── Headings (Space Grotesk) ──────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.darkGray,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
  );

  // ─── Body ─────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGray,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.4,
  );

  // ─── Labels ───────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGray,
  );

  // ─── Button ───────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}
