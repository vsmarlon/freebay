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

class PostFullScreenImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const PostFullScreenImage({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  @override
  State<PostFullScreenImage> createState() => _PostFullScreenImageState();
}

class _PostFullScreenImageState extends State<PostFullScreenImage> {
  final _transformController = TransformationController();

  bool get _isZoomed => _transformController.value != Matrix4.identity();

  void _onDoubleTapDown(TapDownDetails details) {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
    } else {
      final pos = details.localPosition;
      _transformController.value = Matrix4.identity()
        ..translateByDouble(-pos.dx * 2, -pos.dy * 2, 0, 1)
        ..scaleByDouble(3.0, 3.0, 3.0, 1);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 300) {
          widget.onClose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        body: Stack(
          children: [
            GestureDetector(
              onDoubleTapDown: _onDoubleTapDown,
              onDoubleTap: () {},
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 6.0,
                child: Center(
                  child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                  child: const Text(
                    'DESLIZE PARA FECHAR • DUPLO TOQUE PARA ZOOM',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
