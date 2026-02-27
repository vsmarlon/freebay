import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

enum AppCardVariant { compact, full, skeleton }

class AppCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final int priceInCents;
  final double? score;
  final AppCardVariant variant;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.title,
    required this.priceInCents,
    this.imageUrl,
    this.score,
    this.variant = AppCardVariant.full,
    this.onTap,
  });

  const AppCard.skeleton({super.key})
      : variant = AppCardVariant.skeleton,
        title = '',
        priceInCents = 0,
        imageUrl = null,
        score = null,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    if (variant == AppCardVariant.skeleton) {
      return _buildSkeleton(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = (priceInCents / 100).toStringAsFixed(2).replaceAll('.', ',');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.black.withValues(alpha: 0.3)
                  : AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                    maxLines: variant == AppCardVariant.compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ $price',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark
                              ? AppColors.accentGreenLight
                              : AppColors.black,
                        ),
                      ),
                      if (score != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              score!.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.mediumGray
                                    : AppColors.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final height = variant == AppCardVariant.compact ? 120.0 : 160.0;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(height);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(height),
      errorWidget: (context, url, error) => _buildPlaceholder(height),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurpleLight, AppColors.accentGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image, color: AppColors.white, size: 32),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = variant == AppCardVariant.compact ? 120.0 : 160.0;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            color: AppColors.mediumGray.withValues(alpha: 0.2),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  color: AppColors.mediumGray.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 60,
                  color: AppColors.mediumGray.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
