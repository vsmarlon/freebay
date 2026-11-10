import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';

class QuoteSourcePreview extends StatelessWidget {
  const QuoteSourcePreview({super.key, required this.source});

  final QuoteSource? source;

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Text(l10n(context).socialQuoteUnavailable),
      );
    }
    return source!.when(
      post: (id, post) => _preview(
        context,
        post.user,
        post.content ?? '',
        post.firstMedia?.previewUrl,
        () => context.push(AppRoutes.postPath(id)),
      ),
      comment: (id, postId, comment) => _preview(
        context,
        comment.user,
        comment.content,
        null,
        () => context.push(AppRoutes.commentPath(postId, id)),
      ),
    );
  }

  Widget _preview(
    BuildContext context,
    UserEntity? user,
    String content,
    String? imageUrl,
    VoidCallback onTap,
  ) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: context.surfaceHighColor,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n(context).socialQuoteLabel,
                style: AppTypography.labelSmall,
              ),
              if (user != null) ...[
                Spacing.vSm,
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: user.avatarUrl,
                      blurHash: user.avatarBlurHash,
                      isVerified: user.isVerified,
                      size: AppAvatarSize.small,
                    ),
                    Spacing.hSm,
                    Expanded(
                      child: Text(
                        user.displayNameOrDefault,
                        style: AppTypography.labelLarge,
                      ),
                    ),
                  ],
                ),
              ],
              if (content.isNotEmpty) ...[
                Spacing.vSm,
                Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  headers: mediaAuthHeaders(imageUrl),
                  height: 120,
                  fit: BoxFit.cover,
                  cacheWidth: 720,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
