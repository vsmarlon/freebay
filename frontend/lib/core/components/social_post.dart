import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:share_plus/share_plus.dart';

class SocialPost extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final Future<bool> Function()? onLike;
  final Future<bool> Function()? onSave;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;

  final double? price;
  final String? userRole;

  const SocialPost({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.onLike,
    this.onSave,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onUserTap,
    this.price,
    this.userRole,
  });

  @override
  State<SocialPost> createState() => _SocialPostState();
}

class _SocialPostState extends State<SocialPost> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  bool _isLikeLoading = false;
  bool _isImagePressed = false;
  bool _isCardPressed = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _isSaved = widget.isSaved;
    _likesCount = widget.likesCount;
  }

  @override
  void didUpdateWidget(SocialPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
      _likesCount = widget.likesCount;
    }
    if (oldWidget.isSaved != widget.isSaved) {
      _isSaved = widget.isSaved;
    }
  }

  void _handleLike() async {
    if (_isLikeLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isLikeLoading = true);

    if (widget.onLike != null) {
      final success = await widget.onLike!();
      if (success && mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
        });
      }
    }

    if (mounted) setState(() => _isLikeLoading = false);
  }

  void _handleSave() async {
    HapticFeedback.lightImpact();
    if (widget.onSave != null) {
      final success = await widget.onSave!();
      if (success && mounted) {
        setState(() => _isSaved = !_isSaved);
      }
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(
        userName: widget.userName,
        content: widget.content,
        onShareExternal: () async {
          Navigator.pop(context);
          final text = widget.content ?? '';
          await Share.share(
            '${text.isNotEmpty ? '$text\n\n' : ''}Check out this post on FreeBay!',
            subject: 'Post from ${widget.userName}',
          );
        },
        onShareAsPost: () {
          Navigator.pop(context);
          widget.onShare?.call();
        },
      ),
    );
  }

  void _openFullScreenImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImage(
            imageUrl: widget.imageUrl!,
            onClose: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isCardPressed = true),
      onTapUp: (_) => setState(() => _isCardPressed = false),
      onTapCancel: () => setState(() => _isCardPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.linear,
        transform: Matrix4.translationValues(
          _isCardPressed ? 2 : 0,
          _isCardPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child:
            hasImage ? _buildProductLayout(isDark) : _buildTextLayout(isDark),
      ),
    );
  }

  Widget _buildProductLayout(bool isDark) {
    final hasPrice = widget.price != null && widget.price! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(isDark),
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _openFullScreenImage,
                onLongPressStart: (_) => setState(() => _isImagePressed = true),
                onLongPressEnd: (_) => setState(() => _isImagePressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                  transform: _isImagePressed
                      ? (Matrix4.identity()
                        ..setEntry(0, 0, 1.02)
                        ..setEntry(1, 1, 1.02))
                      : Matrix4.identity(),
                  child: Container(
                    color: AppColors.surfaceContainer,
                    child: Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceContainer,
                        child: Icon(
                          Icons.image,
                          color: AppColors.outline,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasPrice)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _PriceTag(price: widget.price!),
                ),
            ],
          ),
        ),
        _buildCardContent(isDark),
      ],
    );
  }

  Widget _buildTextLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(isDark),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.brutalistGradient,
          ),
          child: Text(
            widget.content ?? '',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
        _buildActionsRow(isDark),
      ],
    );
  }

  Widget _buildCardHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onUserTap?.call();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.zero,
              ),
              child: widget.userAvatarUrl != null &&
                      widget.userAvatarUrl!.isNotEmpty
                  ? Image.network(
                      widget.userAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'TIME AGO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.content ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildActionsRow(isDark),
      ],
    );
  }

  Widget _buildActionsRow(bool isDark) {
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
            opacity: _isLikeLoading ? 0.5 : 1.0,
            child: _ActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: _isLiked ? AppColors.primaryContainer : null,
              onTap: _handleLike,
            ),
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onComment?.call();
            },
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.send_outlined,
            onTap: _handleShare,
          ),
          const Spacer(),
          _ActionButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            onTap: _handleSave,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.inverseOnSurface : AppColors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: iconColor ?? defaultColor,
          size: 24,
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double price;

  const _PriceTag({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.onSurface, width: 2),
      ),
      child: Text(
        CurrencyUtils.formatReais(price),
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryContainer,
          height: 1,
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const _FullScreenImage({
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
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
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
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.onSurface.withAlpha(179),
                  child: Text(
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

class _ShareBottomSheet extends StatelessWidget {
  final String userName;
  final String? content;
  final VoidCallback onShareExternal;
  final VoidCallback onShareAsPost;

  const _ShareBottomSheet({
    required this.userName,
    this.content,
    required this.onShareExternal,
    required this.onShareAsPost,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLowest,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.outline,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'COMPARTILHAR POST',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.link,
                color:
                    isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
              title: Text(
                'Compartilhar externamente',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
              subtitle: Text(
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
                color:
                    isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
              title: Text(
                'Compartilhar no perfil',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color:
                      isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                'Criar post com "Compartilhado de @$userName"',
                style: TextStyle(
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
      ),
    );
  }
}
