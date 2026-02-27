import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
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
  final Future<bool> Function()? onLike;
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
    this.onLike,
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
  int _likesCount = 0;
  bool _isImagePressed = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;
  }

  @override
  void didUpdateWidget(SocialPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
      _likesCount = widget.likesCount;
    }
  }

  void _handleLike() async {
    final previousLiked = _isLiked;
    final previousCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    if (widget.onLike != null) {
      final success = await widget.onLike!();
      if (!success) {
        setState(() {
          _isLiked = previousLiked;
          _likesCount = previousCount;
        });
      }
    }
  }

  void _handleShare() {
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on left - clickable with hover effect
            GestureDetector(
              onTap: _openFullScreenImage,
              onLongPressStart: (_) => setState(() => _isImagePressed = true),
              onLongPressEnd: (_) => setState(() => _isImagePressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: hasPrice ? 120 : 200,
                height: hasPrice ? 120 : 220,
                transform: _isImagePressed
                    ? (Matrix4.identity()
                      ..setEntry(0, 0, 1.05)
                      ..setEntry(1, 1, 1.05))
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    width: hasPrice ? 120 : 200,
                    height: hasPrice ? 120 : 220,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image,
                        color: AppColors.mediumGray,
                        size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info and Price on right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clickable user profile
                  GestureDetector(
                    onTap: widget.onUserTap,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isDark
                              ? AppColors.lightGray
                              : AppColors.lightGray,
                          backgroundImage: widget.userAvatarUrl != null
                              ? NetworkImage(widget.userAvatarUrl!)
                              : null,
                          child: widget.userAvatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 16, color: AppColors.mediumGray)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.darkGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.userRole != null)
                                Text(
                                  widget.userRole!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.mediumGray
                                        : AppColors.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPrice) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Preço',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.mediumGray
                            : AppColors.mediumGray,
                      ),
                    ),
                    Text(
                      'R\$ ${widget.price!.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.content ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (hasPrice &&
            widget.content != null &&
            widget.content!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.content!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.white : AppColors.darkGray,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        _buildActionsRow(isDark),
        const SizedBox(height: 8),
        _buildFooter(isDark),
      ],
    );
  }

  Widget _buildTextLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.content ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionsRow(isDark),
        const SizedBox(height: 8),
        _buildFooter(isDark),
      ],
    );
  }

  Widget _buildActionsRow(bool isDark) {
    return Row(
      children: [
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.only(right: 12),
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked
                ? AppColors.primaryPurple
                : (isDark ? AppColors.white : AppColors.darkGray),
            size: 22,
          ),
          onPressed: _handleLike,
        ),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          icon: Icon(
            Icons.chat_bubble_outline,
            color: isDark ? AppColors.white : AppColors.darkGray,
            size: 22,
          ),
          onPressed: widget.onComment,
        ),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          icon: Icon(
            Icons.send_outlined,
            color: isDark ? AppColors.white : AppColors.darkGray,
            size: 22,
          ),
          onPressed: _handleShare,
        ),
        const Spacer(),
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.bookmark_border,
            color: isDark ? AppColors.white : AppColors.darkGray,
            size: 22,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      children: [
        Text(
          '$_likesCount Curtidas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        const SizedBox(width: 8),
        if (widget.commentsCount > 0)
          Text(
            'Ver ${widget.commentsCount} comentários',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
          ),
      ],
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
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
                child: Text(
                  'Deslize para fechar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
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
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Compartilhar post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Compartilhar externamente'),
              subtitle: const Text('WhatsApp, Instagram, etc.'),
              onTap: onShareExternal,
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Compartilhar no perfil'),
              subtitle: Text('Criar post com "Compartilhado de @$userName"'),
              onTap: onShareAsPost,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
