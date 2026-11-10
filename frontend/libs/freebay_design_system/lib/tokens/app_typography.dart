import 'package:flutter/material.dart';

extension AppTextWeight on TextStyle {
  TextStyle weight(int wght) => copyWith(
    fontWeight: FontWeight.values[(wght ~/ 100) - 1],
    fontVariations: [FontVariation('wght', wght.toDouble())],
  );
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String displayFontFamily = 'SpaceGrotesk';
  static const String headlineFontFamily = displayFontFamily;

  static const TextStyle displayHero = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation('wght', 800)],
    letterSpacing: -2.0,
    height: 0.95,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -1.0,
    height: 1.15,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.5,
    height: 1.20,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.2,
    height: 1.30,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    height: 1.55,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    height: 1.50,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0.1,
    height: 1.40,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0.2,
    height: 1.20,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0.3,
    height: 1.20,
  );

  static const TextStyle brutalistTag = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0.6,
    height: 1.0,
  );

  static const TextStyle button = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0.3,
    height: 1.0,
  );
}
