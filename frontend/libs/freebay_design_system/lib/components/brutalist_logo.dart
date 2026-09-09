import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_depth.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

class BrutalistLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final String? customTagline;

  const BrutalistLogo({
    super.key,
    this.fontSize = 44.0,
    this.showTagline = true,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                const Shadow(
                  color: AppColors.primaryContainer,
                  offset: AppDepth.shadowOffsetSmall,
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
