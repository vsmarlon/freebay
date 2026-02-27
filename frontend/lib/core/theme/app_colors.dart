import 'package:flutter/material.dart';

/// FreeBay brand colors from the C2C platform plan
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryPurpleLight = Color(0xFF9F67FF);
  static const Color primaryPurpleDark = Color(0xFF5B21B6);

  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenLight = Color(0xFF34D399);
  static const Color accentGreenDark = Color(0xFF059669);

  // ─── Neutrals ─────────────────────────────────────────
  static const Color darkGray = Color(0xFF1F2937);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);

  // ─── Semantic ─────────────────────────────────────────
  static const Color success = accentGreen;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Background ───────────────────────────────────────
  static const Color backgroundLight = lightGray;
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = white;
  static const Color surfaceDark = Color(0xFF1E293B);
}
