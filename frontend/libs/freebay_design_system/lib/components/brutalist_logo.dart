import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

class BrutalistLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool showBadge;
  final String? customTagline;

  const BrutalistLogo({
    super.key,
    this.fontSize = 44.0,
    this.showTagline = true,
    this.showBadge = true,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBadge) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryContainer.withAlpha(40)
                  : AppColors.primaryContainer.withAlpha(25),
              border: Border.all(
                color: AppColors.primaryContainer,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'DECENTRALIZED COMMERCE',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.onPrimaryContainer
                        : AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Main Brand Logo Text
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'FREEBAY',
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
              color: context.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.primaryContainer.withAlpha(120),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            children: const [
              TextSpan(
                text: '!',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            (customTagline ?? 'TRADE YOUR WORLD').toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
