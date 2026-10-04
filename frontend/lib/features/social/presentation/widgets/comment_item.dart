import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/features/social/data/entities/comment_entity.dart';

class CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final bool isReplying;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback? onUserTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.isReplying,
    required this.isLiked,
    required this.likesCount,
    required this.onReply,
    required this.onLike,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.surfaceMidColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDepth.borderThin),
        child: ColoredBox(
          color: context.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onUserTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.surfaceMidColor,
                      image: comment.user?.avatarUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                comment.user!.avatarUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: comment.user?.avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: context.textSecondary,
                          )
                        : null,
                  ),
                ),
                Spacing.hSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onUserTap,
                        child: Text(
                          comment.user?.displayName ?? 'Usuário',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      BrutalistHighlightedText(
                        text: comment.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        onLinkTap: (url) =>
                            showBrutalistSafeLinkDialog(context, url),
                        onMentionTap: (mention) {
                          final username = mention.replaceFirst('@', '');
                          context.push(AppRoutes.peopleSearchWith(username));
                        },
                        onHashtagTap: (tag) {
                          context.push(AppRoutes.postSearchWith(tag));
                        },
                      ),
                      Spacing.vXs,
                      Row(
                        children: [
                          Text(
                            localizedTimeAgo(context, comment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                          Spacing.hMd,
                          GestureDetector(
                            onTap: onReply,
                            child: Text(
                              comment.replies.isNotEmpty
                                  ? 'Responder • ${comment.replies.length} ${comment.replies.length == 1 ? 'resposta' : 'respostas'}'
                                  : 'Responder',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                          Spacing.hMd,
                          GestureDetector(
                            onTap: onLike,
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 14,
                                  color: isLiked
                                      ? AppColors.error
                                      : context.textSecondary,
                                ),
                                Spacing.hXs,
                                if (likesCount > 0)
                                  Text(
                                    likesCount.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLiked
                                          ? AppColors.error
                                          : context.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
