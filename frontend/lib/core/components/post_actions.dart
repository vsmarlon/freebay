import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

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
          top: BorderSide(
            color: AppColors.onSurface.withAlpha(26),
            width: 1,
          ),
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
          const SizedBox(width: 16),
          PostActionButton(
            icon: Icons.chat_bubble_outline,
            label: commentsCount > 0 ? commentsCount.toString() : null,
            onTap: () {
              HapticFeedback.lightImpact();
              onComment?.call();
            },
          ),
          const SizedBox(width: 16),
          PostActionButton(
            icon: isReposted ? Icons.repeat : Icons.repeat,
            iconColor: isReposted ? AppColors.primaryPurple : null,
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
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontFamily: 'Inter',
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

class PostFullScreenImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const PostFullScreenImage({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 300) {
          onClose();
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface,
                    border: Border.all(
                        color: AppColors.surfaceContainerLowest, width: 2),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.onSurface.withAlpha(179),
                  child: const Text(
                    'SWIPE TO CLOSE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
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
  final VoidCallback onShareAsPost;
  final bool isDark;

  const PostShareBottomSheet({
    super.key,
    required this.userName,
    this.content,
    required this.onShareExternal,
    required this.onShareAsPost,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistSheetScaffold(
      title: 'COMPARTILHAR POST',
      showDragHandle: true,
      useSafeArea: false,
      padding: const EdgeInsets.all(16),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.link,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
            ),
            title: Text(
              'Compartilhar externamente',
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
            ),
            subtitle: const Text(
              'WhatsApp, Instagram, etc.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.outline,
                fontSize: 12,
              ),
            ),
            onTap: onShareExternal,
          ),
          ListTile(
            leading: Icon(
              Icons.article_outlined,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
            ),
            title: Text(
              'Compartilhar no perfil',
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
            ),
            subtitle: Text(
              'Criar post com "Compartilhado de @$userName"',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.outline,
                fontSize: 12,
              ),
            ),
            onTap: onShareAsPost,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
