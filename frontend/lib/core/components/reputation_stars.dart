import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/spacing.dart';

class ReputationStars extends StatelessWidget {
  final double score;
  final int reviewCount;
  final bool showCount;
  final double size;

  const ReputationStars({
    super.key,
    required this.score,
    this.reviewCount = 0,
    this.showCount = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (score >= starValue) {
            icon = Icons.star;
            color = AppColors.warning;
          } else if (score >= starValue - 0.5) {
            icon = Icons.star_half;
            color = AppColors.warning;
          } else {
            icon = Icons.star_outline;
            color = AppColors.mediumGray.withAlpha(128);
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showCount && reviewCount > 0) ...[
          Spacing.hXs,
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
