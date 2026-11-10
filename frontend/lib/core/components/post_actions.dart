import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final bool isLikeLoading;
  final bool allowRepost;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onRepost;
  final VoidCallback? onComment;
  final VoidCallback? onQuote;
  final VoidCallback? onMore;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.isReposted,
    required this.isLikeLoading,
    this.allowRepost = true,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onLike,
    required this.onSave,
    required this.onRepost,
    this.onComment,
    this.onQuote,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.onSurface.withAlpha(26)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.spaceBetween,
        spacing: Spacing.sm,
        runSpacing: Spacing.xs,
        children: [
          Opacity(
            opacity: isLikeLoading ? 0.5 : 1.0,
            child: PostActionButton(
              key: const ValueKey('post-action-like'),
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: isLiked ? context.colors.primary : null,
              label: likesCount > 0 ? likesCount.toString() : null,
              onTap: onLike,
            ),
          ),
          PostActionButton(
            key: const ValueKey('post-action-comment'),
            icon: Icons.chat_bubble_outline,
            label: commentsCount > 0 ? commentsCount.toString() : null,
            semanticLabel: strings.accessibilityCommentCount(commentsCount),
            onTap: () {
              HapticFeedback.lightImpact();
              onComment?.call();
            },
          ),
          if (allowRepost)
            PostActionButton(
              key: const ValueKey('post-action-repost'),
              icon: Icons.repeat,
              iconColor: isReposted ? context.colors.primary : null,
              label: sharesCount > 0 ? sharesCount.toString() : null,
              semanticLabel: strings.feedRepost,
              onTap: onRepost,
              onLongPress: onQuote == null
                  ? null
                  : () => showBrutalistSheet<void>(
                      context: context,
                      title: strings.feedRepost,
                      builder: (sheetContext) => ListTile(
                        leading: const Icon(Icons.format_quote),
                        title: Text(strings.socialQuoteLabel),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onQuote!();
                        },
                      ),
                    ),
            ),
          if (onQuote != null) ...[
            PostActionButton(
              key: const ValueKey('post-action-quote'),
              icon: Icons.format_quote,
              semanticLabel: strings.socialQuoteLabel,
              onTap: onQuote!,
            ),
          ],
          PostActionButton(
            key: const ValueKey('post-action-save'),
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            semanticLabel: isSaved
                ? strings.feedUnsavePost
                : strings.feedSavePost,
            onTap: onSave,
          ),
          if (onMore != null)
            PostActionButton(
              key: const ValueKey('post-action-more'),
              icon: Icons.more_horiz,
              semanticLabel: strings.accessibilityMoreOptions,
              onTap: onMore!,
            ),
        ],
      ),
    );
  }
}

class PostActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String? label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  const PostActionButton({
    super.key,
    required this.icon,
    this.iconColor,
    this.label,
    required this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = context.textPrimary;

    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor ?? defaultColor, size: 24),
                if (label != null) ...[
                  Spacing.hXs,
                  Text(
                    label!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: iconColor ?? defaultColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
