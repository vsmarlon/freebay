import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/post_actions.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
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
  final bool isReposted;
  final Future<bool> Function()? onLike;
  final Future<bool> Function()? onSave;
  final Future<bool> Function()? onRepost;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;

  final double? price;
  final String? userRole;
  final bool isVerified;

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
    this.isReposted = false,
    this.onLike,
    this.onSave,
    this.onRepost,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onUserTap,
    this.price,
    this.userRole,
    this.isVerified = false,
  });

  @override
  State<SocialPost> createState() => _SocialPostState();
}

class _SocialPostState extends State<SocialPost> {
  bool _isLikeLoading = false;
  bool _isImagePressed = false;
  bool _isCardPressed = false;

  void _handleLike() async {
    if (_isLikeLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isLikeLoading = true);
    if (widget.onLike != null) {
      await widget.onLike!();
    }
    if (mounted) setState(() => _isLikeLoading = false);
  }

  void _handleSave() async {
    HapticFeedback.lightImpact();
    if (widget.onSave != null) {
      await widget.onSave!();
    }
  }

  @pragma('vm:entry-point')
void _handleShareExternal() {
    // External share functionality - can be triggered from overflow menu
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PostShareBottomSheet(
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
          return PostFullScreenImage(
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
          color: context.surfaceColor,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child:
            hasImage ? _buildProductLayout(context) : _buildTextLayout(context),
      ),
    );
  }

  Widget _buildProductLayout(BuildContext context) {
    final hasPrice = widget.price != null && widget.price! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(context),
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
        _buildCardContent(context),
      ],
    );
  }

  Widget _buildTextLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(context),
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
        _buildActionsRow(),
      ],
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onUserTap,
                        child: Text(
                          widget.userName,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ],
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
          _PostTypePill(isProduct: widget.price != null && widget.price! > 0),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            widget.content ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildActionsRow(),
      ],
    );
  }

  Widget _buildActionsRow() {
    return PostActions(
      isLiked: widget.isLiked,
      isSaved: widget.isSaved,
      isReposted: widget.isReposted,
      isLikeLoading: _isLikeLoading,
      likesCount: widget.likesCount,
      commentsCount: widget.commentsCount,
      sharesCount: widget.sharesCount,
      onLike: _handleLike,
      onSave: _handleSave,
      onRepost: _handleRepost,
      onComment: widget.onComment,
    );
  }

  void _handleRepost() async {
    HapticFeedback.lightImpact();
    if (widget.onRepost != null) {
      await widget.onRepost!();
    }
  }
}

class _PostTypePill extends StatelessWidget {
  final bool isProduct;

  const _PostTypePill({required this.isProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: isProduct ? AppColors.brutalistGradient : null,
        color: isProduct ? null : AppColors.onSurface,
        border: Border.all(color: AppColors.onSurface, width: 2),
      ),
      child: Text(
        isProduct ? 'VENDA' : 'SOCIAL',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.white,
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

