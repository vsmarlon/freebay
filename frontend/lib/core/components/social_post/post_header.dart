import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/social_post/post_labels.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class SocialPostHeader extends StatelessWidget {
  final String userName;
  final String? userAvatarUrl;
  final String? userAvatarBlurHash;
  final bool isVerified;
  final bool isSelling;
  final DateTime? createdAt;
  final VoidCallback? onUserTap;

  const SocialPostHeader({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    this.userAvatarBlurHash,
    required this.isVerified,
    required this.isSelling,
    required this.createdAt,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onUserTap?.call();
            },
            child: Container(
              width: 40,
              height: 40,
              color: AppColors.primaryContainer,
              child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: userAvatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      placeholder: (_, _) => BlurHashPlaceholder(
                        hash: userAvatarBlurHash,
                        fallback: const Icon(
                          Icons.person,
                          color: AppColors.onPrimary,
                          size: 20,
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.person,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onUserTap,
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      Spacing.hXs,
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ],
                ),
                Text(
                  createdAt != null
                      ? localizedTimeAgo(context, createdAt!)
                      : l10n(context).timeAgoNow,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PostTypePill(isProduct: isSelling),
        ],
      ),
    );
  }
}
