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
  });

  @override
  Widget build(BuildContext context) {
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
              iconColor: isLiked ? AppColors.primaryContainer : null,
              label: likesCount > 0 ? likesCount.toString() : null,
              onTap: onLike,
            ),
          ),
          if (allowRepost)
            PostActionButton(
              key: const ValueKey('post-action-comment'),
              icon: Icons.chat_bubble_outline,
              label: commentsCount > 0 ? commentsCount.toString() : null,
              onTap: () {
                HapticFeedback.lightImpact();
                onComment?.call();
              },
            ),
          PostActionButton(
            key: const ValueKey('post-action-repost'),
            icon: isReposted ? Icons.repeat : Icons.repeat,
            iconColor: isReposted ? AppColors.primaryContainer : null,
            label: sharesCount > 0 ? sharesCount.toString() : null,
            semanticLabel: l10n(context).feedRepost,
            onTap: onRepost,
            onLongPress: onQuote == null
                ? null
                : () => showBrutalistSheet<void>(
                    context: context,
                    title: l10n(context).feedRepost,
                    builder: (sheetContext) => ListTile(
                      leading: const Icon(Icons.format_quote),
                      title: Text(l10n(context).socialQuoteLabel),
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
              semanticLabel: l10n(context).socialQuoteLabel,
              onTap: onQuote!,
            ),
          ],
          PostActionButton(
            key: const ValueKey('post-action-save'),
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            onTap: onSave,
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

class PostShareBottomSheet extends StatelessWidget {
  final String userName;
  final String? content;
  final VoidCallback onShareExternal;
  final VoidCallback? onShareAsPost;

  const PostShareBottomSheet({
    super.key,
    required this.userName,
    this.content,
    required this.onShareExternal,
    required this.onShareAsPost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onShareAsPost != null)
          ListTile(
            leading: Icon(Icons.link, color: context.textPrimary),
            title: Text(
              'Compartilhar externamente',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: context.textPrimary,
              ),
            ),
            subtitle: const Text(
              'WhatsApp, Instagram, etc.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: AppColors.outline,
                fontSize: 12,
              ),
            ),
            onTap: onShareExternal,
          ),
        ListTile(
          leading: Icon(Icons.article_outlined, color: context.textPrimary),
          title: Text(
            'Compartilhar no perfil',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            'Criar post com "Compartilhado de @$userName"',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: AppColors.outline,
              fontSize: 12,
            ),
          ),
          onTap: onShareAsPost,
        ),
        Spacing.vMd,
      ],
    );
  }
}
