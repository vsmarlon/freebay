import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final VoidCallback? onTapUser;

  const ReviewCard({super.key, required this.review, this.onTapUser});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final strings = l10n(context);
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
                  blurHash: review.reviewer?.avatarBlurHash,
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
                        review.reviewer?.displayName ??
                            strings.commonUnknownUser,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
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
                      _getReviewTypeLabel(context),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateFormat.format(review.createdAt),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
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
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        showAppImageViewer(context, review.images[index]),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline, width: 2),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: review.images[index],
                        httpHeaders: mediaAuthHeaders(review.images[index]),
                        fit: BoxFit.cover,
                        memCacheWidth: 250,
                        memCacheHeight: 250,
                        placeholder: (_, _) => Container(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getReviewTypeLabel(BuildContext context) {
    final strings = l10n(context);
    return review.type == ReviewType.buyerReviewingSeller
        ? strings.reviewTypeBuyer
        : strings.reviewTypeSeller;
  }
}
