import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tokens for the Neo-Brutalist Refined design system.
/// All text uses Space Grotesk with weight differentiation.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'SpaceGrotesk';
  static const String headlineFontFamily = 'SpaceGrotesk';

  // ─── Display Hero ──────────────────────────────────────
  static const TextStyle displayHero = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w900,
    letterSpacing: -2.5,
    height: 0.95,
    color: AppColors.darkGray,
  );

  // ─── Headings (Space Grotesk) ──────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.darkGray,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    height: 1.3,
  );

  // ─── Body (Space Grotesk – lighter weights) ────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkGray,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.5,
    letterSpacing: 0.05,
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
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGray,
    letterSpacing: 0.1,
  );

  // ─── Tag / Badge ──────────────────────────────────────
  static const TextStyle brutalistTag = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // ─── Button ───────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: headlineFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.white,
  );
}

