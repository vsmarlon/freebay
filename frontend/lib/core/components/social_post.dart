import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/app_image_viewer.dart';
import 'package:freebay/core/components/social_post/post_action_chrome.dart';
import 'package:freebay/core/components/social_post/post_content.dart';
import 'package:freebay/core/components/social_post/post_header.dart';
import 'package:freebay/core/components/social_post/post_labels.dart';
import 'package:freebay/core/components/social_post/post_media.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

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
    if (!widget.isLiked) _handleLike();
    setState(() => _showHeartBurst = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  Future<void> _handleLike() async {
    if (_isLikeLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isLikeLoading = true);
    await widget.onLike?.call();
    if (mounted) setState(() => _isLikeLoading = false);
  }

  Future<void> _handleSave() async {
    HapticFeedback.lightImpact();
    await widget.onSave?.call();
  }

  Future<void> _handleRepost() async {
    HapticFeedback.lightImpact();
    await widget.onRepost?.call();
  }

  Widget _actions() => SocialPostActionChrome(
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
          _isCardPressed ? AppDepth.pressOffset : 0,
          _isCardPressed ? AppDepth.pressOffset : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(color: context.borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SocialPostHeader(
              userName: widget.userName,
              userAvatarUrl: widget.userAvatarUrl,
              isVerified: widget.isVerified,
              isSelling: widget.isSelling,
              createdAt: widget.createdAt,
              onUserTap: widget.onUserTap,
            ),
            if (hasImage || widget.isSelling)
              Column(
                children: [
                  SocialPostMedia(
                    imageUrl: widget.imageUrl,
                    showHeartBurst: _showHeartBurst,
                    isPressed: _isImagePressed,
                    onTap: () => showAppImageViewer(context, widget.imageUrl!),
                    onDoubleTap: _triggerDoubleTapLike,
                    onPressedChanged: (pressed) =>
                        setState(() => _isImagePressed = pressed),
                    priceTag: widget.price != null && widget.price! > 0
                        ? PostPriceTag(price: widget.price!)
                        : null,
                  ),
                  SocialPostContent(
                    content: widget.content,
                    compact: false,
                    actions: _actions(),
                  ),
                ],
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceMidColor,
                  border: const Border(
                    left: BorderSide(
                      color: AppColors.primaryContainer,
                      width: 4,
                    ),
                  ),
                ),
                child: SocialPostContent(
                  content: widget.content,
                  compact: true,
                  actions: _actions(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
