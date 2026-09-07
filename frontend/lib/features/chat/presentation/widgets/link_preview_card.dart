import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';

class LinkPreviewCard extends StatelessWidget {
  final Map<String, dynamic>? metadata;

  const LinkPreviewCard({super.key, this.metadata});

  @override
  Widget build(BuildContext context) {
    final meta = metadata;
    if (meta == null) return const SizedBox.shrink();

    final targetUrl = meta['url'] as String?;
    final imageUrl = meta['imageUrl'] as String?;
    final title = meta['title'] as String?;
    final description = meta['description'] as String?;
    final siteName = meta['siteName'] as String?;

    if (imageUrl == null &&
        title == null &&
        description == null &&
        targetUrl == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: targetUrl != null && targetUrl.isNotEmpty
          ? () => showBrutalistSafeLinkDialog(context, targetUrl)
          : null,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
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
                  if (siteName != null && siteName.isNotEmpty)
                    Text(
                      siteName,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (title != null && title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      title,
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
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
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
      ),
    );
  }
}
