import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/components/reputation_stars.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final VoidCallback? onTapUser;

  const ReviewCard({
    super.key,
    required this.review,
    this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onTapUser,
                child: UserAvatar(
                  imageUrl: review.reviewer?.avatarUrl,
                  size: AppAvatarSize.small,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onTapUser,
                      child: Text(
                        review.reviewer?.displayNameOrDefault ?? 'Usuário',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.inverseOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getReviewTypeLabel(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateFormat.format(review.createdAt),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReputationStars(
            score: review.score.toDouble(),
            showCount: false,
            size: 20,
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getReviewTypeLabel() {
    return review.type == ReviewType.buyerReviewingSeller
        ? 'Comprador'
        : 'Vendedor';
  }
}
