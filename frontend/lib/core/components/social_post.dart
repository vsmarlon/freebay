import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/post_actions.dart';
import 'package:freebay/core/components/app_image_viewer.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/utils/time_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/brutalist_highlighted_text.dart';
import 'package:freebay/core/components/brutalist_safe_link_dialog.dart';
import 'package:freebay/core/router/app_routes.dart';

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
  final bool isSelling;
  final String? userRole;
  final bool isVerified;
  final DateTime? createdAt;

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
    this.isSelling = false,
    this.userRole,
    this.isVerified = false,
    this.createdAt,
  });

  @override
  State<SocialPost> createState() => _SocialPostState();
}

class _SocialPostState extends State<SocialPost> {
  bool _isLikeLoading = false;
  bool _isImagePressed = false;
  bool _isCardPressed = false;
  bool _showHeartBurst = false;

  void _triggerDoubleTapLike() {
    HapticFeedback.mediumImpact();
    if (!widget.isLiked) {
      _handleLike();
    }
    setState(() => _showHeartBurst = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

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
    HapticFeedback.lightImpact();
    showBrutalistSheet(
      context: context,
      title: 'COMPARTILHAR POST',
      builder: (context) => PostShareBottomSheet(
        userName: widget.userName,
        content: widget.content,
        onShareExternal: () async {
          Navigator.pop(context);
          final text = widget.content ?? '';
          await SharePlus.instance.share(
            ShareParams(
              text:
                  '${text.isNotEmpty ? '$text\n\n' : ''}Check out this post on FreeBay!',
              subject: 'Post from ${widget.userName}',
            ),
          );
        },
        onShareAsPost: widget.onShare == null
            ? null
            : () {
                Navigator.pop(context);
                widget.onShare?.call();
              },
      ),
    );
  }

  void _openFullScreenImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;
    showAppImageViewer(context, widget.imageUrl!);
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
        duration: AppMotion.base,
        transform: Matrix4.translationValues(
          _isCardPressed ? AppDepth.pressOffset : 0.0,
          _isCardPressed ? AppDepth.pressOffset : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(color: context.borderColor, width: 2),
        ),
        child: hasImage || widget.isSelling
            ? _buildProductLayout(context)
            : _buildTextLayout(context),
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
                onDoubleTap: _triggerDoubleTapLike,
                onLongPressStart: (_) => setState(() => _isImagePressed = true),
                onLongPressEnd: (_) => setState(() => _isImagePressed = false),
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  transform: _isImagePressed
                      ? (Matrix4.identity()
                          ..setEntry(0, 0, 1.02)
                          ..setEntry(1, 1, 1.02))
                      : Matrix4.identity(),
                  child: Container(
                    color: context.surfaceMidColor,
                    child: widget.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 1080,
                            placeholder: (context, url) =>
                                Container(color: context.surfaceMidColor),
                            errorWidget: (context, error, stackTrace) =>
                                Container(
                                  color: context.surfaceMidColor,
                                  child: Icon(
                                    Icons.image,
                                    color: context.textSecondary,
                                    size: 48,
                                  ),
                                ),
                          )
                        : Center(
                            child: Text(
                              'VENDA',
                              style: AppTypography.h2.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (_showHeartBurst)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1.2),
                    duration: AppMotion.enter,
                    curve: AppMotion.enterCurve,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            border: Border.all(
                              color: AppColors.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppColors.primaryContainer,
                            size: 64,
                          ),
                        ),
                      );
                    },
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
          decoration: const BoxDecoration(
            gradient: AppColors.brutalistGradient,
          ),
          child: BrutalistHighlightedText(
            text: widget.content ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimary,
            ),
            linkColor: AppColors.onPrimary,
            mentionColor: AppColors.onPrimary,
            hashtagColor: AppColors.onPrimary,
            onLinkTap: (url) => showBrutalistSafeLinkDialog(context, url),
            onMentionTap: (mention) {
              final username = mention.replaceFirst('@', '');
              context.push(AppRoutes.peopleSearchWith(username));
            },
            onHashtagTap: (tag) {
              context.push(AppRoutes.postSearchWith(tag));
            },
          ),
        ),
        _buildActionsRow(),
      ],
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 2),
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
              ),
              child:
                  widget.userAvatarUrl != null &&
                      widget.userAvatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.userAvatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      placeholder: (_, _) => const Icon(
                        Icons.person,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.person,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppColors.onPrimary,
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
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.isVerified) ...[
                      Spacing.hXs,
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ],
                ),
                Text(
                  widget.createdAt != null
                      ? TimeUtils.timeAgo(widget.createdAt!)
                      : 'agora',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _PostTypePill(isProduct: widget.isSelling),
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
          child: BrutalistHighlightedText(
            text: widget.content ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            onLinkTap: (url) => showBrutalistSafeLinkDialog(context, url),
            onMentionTap: (mention) {
              final username = mention.replaceFirst('@', '');
              context.push(AppRoutes.peopleSearchWith(username));
            },
            onHashtagTap: (tag) {
              context.push(AppRoutes.postSearchWith(tag));
            },
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
        color: isProduct ? null : context.surfaceMidColor,
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Text(
        isProduct ? 'VENDA' : 'SOCIAL',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isProduct ? AppColors.onPrimary : context.textPrimary,
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
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 2),
      ),
      child: Text(
        CurrencyUtils.formatReais(price),
        style: const TextStyle(
          fontFamily: AppTypography.headlineFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryContainer,
          height: 1,
        ),
      ),
    );
  }
}
