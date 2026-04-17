import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand Primary - Digital Brutalist ──────────────────────
  static const Color primary = Color(0xFF660062);
  static const Color primaryContainer = Color(0xFF8A1083);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFF9DEE);

  // ─── Surface Hierarchy (Light Mode) ────────────────────────
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // ─── Surface Hierarchy (Dark Mode) ────────────────────────
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceContainerDark = Color(0xFF1E293B);
  static const Color surfaceContainerLowDark = Color(0xFF1B1B1B);

  // ─── On Surface ───────────────────────────────────────────
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceVariant = Color(0xFF52424E);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);
  static const Color inverseSurface = Color(0xFF303030);

  // ─── Outline ─────────────────────────────────────────────
  static const Color outline = Color(0xFF85727F);
  static const Color outlineVariant = Color(0xFFD7C0CF);

  // ─── Secondary & Tertiary ────────────────────────────────
  static const Color secondary = Color(0xFF5E5E5E);
  static const Color secondaryContainer = Color(0xFFE2E2E2);
  static const Color tertiary = Color(0xFF343637);
  static const Color tertiaryContainer = Color(0xFF4B4D4D);

  // ─── Semantic Colors ─────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Legacy Aliases ───────────────────────────────────────
  static const Color primaryBrand = primaryContainer;
  static const Color primaryBrandLight = primaryContainer;
  static const Color primaryBrandDark = primary;
  static const Color primaryPurple = primaryContainer;
  static const Color primaryPurpleLight = primaryContainer;
  static const Color primaryPurpleDark = primary;
  static const Color accentGreen = success;
  static const Color accentGreenLight = Color(0xFF34D399);
  static const Color accentGreenDark = Color(0xFF059669);
  static const Color accentOrange = warning;
  static const Color accentOrangeLight = Color(0xFFFBBF24);
  static const Color accentOrangeDark = Color(0xFFD97706);

  // ─── Neutrals ─────────────────────────────────────────────
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);
  static const Color backgroundLight = surface;
  static const Color backgroundDark = surfaceDark;
  static const Color surfaceLight = surfaceContainerLowest;
  static const Color surfaceLightOld = white;

  // ─── Glassmorphism (Legacy) ───────────────────────────────
  static const Color glassLight = Color(0xF0FFFFFF);
  static const Color glassDark = Color(0xE60F172A);
  static const Color glassBorderLight = Color(0x20FFFFFF);
  static const Color glassBorderDark = Color(0x30FFFFFF);
  static const Color glassHighlightLight = Color(0x0AFFFFFF);
  static const Color glassHighlightDark = Color(0x0AFFFFFF);

  // ─── Brutalist Gradient ──────────────────────────────────
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
