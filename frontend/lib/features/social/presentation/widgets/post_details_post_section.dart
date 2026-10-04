import 'package:flutter/material.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PostDetailsPostSection extends StatelessWidget {
  final PostEntity post;
  final int likesCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final Future<bool> Function() onLike;
  final Future<bool> Function() onSave;
  final Future<bool> Function() onRepost;
  final VoidCallback onUserTap;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const PostDetailsPostSection({
    super.key,
    required this.post,
    required this.likesCount,
    required this.sharesCount,
    required this.isLiked,
    required this.isSaved,
    required this.isReposted,
    required this.onLike,
    required this.onSave,
    required this.onRepost,
    required this.onUserTap,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SocialPost(
      userId: post.user.id,
      userName: post.user.displayNameOrDefault,
      userAvatarUrl: post.user.avatarUrl,
      userAvatarBlurHash: post.user.avatarBlurHash,
      content: post.content,
      imageUrl: post.imageUrl,
      imageBlurHash: post.audience == PostAudience.everyone
          ? post.imageBlurHash
          : null,
      isCloseFriends: post.audience == PostAudience.closeFriends,
      closeFriendsLabel: l10n(context).feedAudienceCloseFriends,
      likesCount: likesCount,
      commentsCount: post.commentsCount,
      sharesCount: sharesCount,
      isLiked: isLiked,
      isSaved: isSaved,
      isReposted: isReposted,
      isVerified: post.user.isVerified,
      createdAt: post.createdAt,
      heroTag: 'post-media-${post.id}',
      onUserTap: onUserTap,
      onLike: onLike,
      onSave: onSave,
      onRepost: onRepost,
      onComment: onComment,
      onShare: onShare,
    );
  }
}
