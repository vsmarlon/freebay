import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
        RatingBar.builder(
          initialRating: score,
          minRating: 0,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: size,
          ignoreGestures: true,
          unratedColor: AppColors.mediumGray.withAlpha(128),
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: AppColors.warning),
          onRatingUpdate: (_) {},
        ),
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
