import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final bool isLikeLoading;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onRepost;
  final VoidCallback? onComment;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.isReposted,
    required this.isLikeLoading,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onLike,
    required this.onSave,
    required this.onRepost,
    this.onComment,
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
      child: Row(
        children: [
          Opacity(
            opacity: isLikeLoading ? 0.5 : 1.0,
            child: PostActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: isLiked ? AppColors.primaryContainer : null,
              label: likesCount > 0 ? likesCount.toString() : null,
              onTap: onLike,
            ),
          ),
          Spacing.hMd,
          PostActionButton(
            icon: Icons.chat_bubble_outline,
            label: commentsCount > 0 ? commentsCount.toString() : null,
            onTap: () {
              HapticFeedback.lightImpact();
              onComment?.call();
            },
          ),
          Spacing.hMd,
          PostActionButton(
            icon: isReposted ? Icons.repeat : Icons.repeat,
            iconColor: isReposted ? AppColors.primaryContainer : null,
            label: sharesCount > 0 ? sharesCount.toString() : null,
            onTap: onRepost,
          ),
          const Spacer(),
          PostActionButton(
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

  const PostActionButton({
    super.key,
    required this.icon,
    this.iconColor,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = context.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
