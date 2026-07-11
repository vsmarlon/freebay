import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/og_metadata_entity.dart';

class LinkPreviewCard extends StatelessWidget {
  final OgMetadataEntity? metadata;

  const LinkPreviewCard({super.key, this.metadata});

  @override
  Widget build(BuildContext context) {
    if (metadata == null) return const SizedBox.shrink();

    final hasImage =
        metadata!.imageUrl != null && metadata!.imageUrl!.isNotEmpty;
    final hasTitle = metadata!.title != null && metadata!.title!.isNotEmpty;
    final hasDescription =
        metadata!.description != null && metadata!.description!.isNotEmpty;
    final hasSite =
        metadata!.siteName != null && metadata!.siteName!.isNotEmpty;

    if (!hasImage && !hasTitle && !hasDescription) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: metadata!.imageUrl!,
              width: 260,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 260,
                height: 120,
                color: AppColors.surfaceContainerHighest,
              ),
              errorWidget: (context, url, error) => Container(
                width: 260,
                height: 120,
                color: AppColors.surfaceContainerHighest,
                child: const Icon(Icons.link, size: 24),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasSite)
                  Text(
                    metadata!.siteName!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (hasTitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    metadata!.title!,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (hasDescription) ...[
                  const SizedBox(height: 2),
                  Text(
                    metadata!.description!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
