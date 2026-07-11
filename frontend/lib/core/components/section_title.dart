import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_typography.dart';
import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  final Widget? trailing;
  final double fontSize;

  const SectionTitle({
    super.key,
    required this.text,
    this.isDark = false,
    this.trailing,
    this.fontSize = 48,
  });

  const SectionTitle.compact({
    super.key,
    required this.text,
    this.isDark = false,
    this.trailing,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: -2,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
