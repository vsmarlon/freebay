import 'package:flutter/material.dart';
import 'package:freebay/core/components/post_actions.dart';

class SocialPostActionChrome extends StatelessWidget {
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

  const SocialPostActionChrome({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.isReposted,
    required this.isLikeLoading,
    required this.allowRepost,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onLike,
    required this.onSave,
    required this.onRepost,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return PostActions(
      isLiked: isLiked,
      isSaved: isSaved,
      isReposted: isReposted,
      isLikeLoading: isLikeLoading,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      onLike: onLike,
      onSave: onSave,
      onRepost: onRepost,
      allowRepost: allowRepost,
      onComment: onComment,
    );
  }
}
