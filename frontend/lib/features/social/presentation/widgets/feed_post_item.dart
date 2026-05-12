import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/social_post.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';

class FeedPostItem extends ConsumerStatefulWidget {
  final PostEntity post;

  const FeedPostItem({super.key, required this.post});

  @override
  ConsumerState<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends ConsumerState<FeedPostItem> {


  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final price = post.product?.price != null && post.product!.price > 0
        ? post.product!.price / 100
        : null;

    final likesState = ref.watch(likesProvider);
    final isLiked = likesState.getLikedOverride(post.id) ?? post.isLiked;
    final likesCount = likesState.getCountOverride(post.id) ?? post.likesCount;
    
    final savesState = ref.watch(savesProvider);
    final isSaved = savesState.getSavedOverride(post.id) ?? post.isSaved;

    final repostsState = ref.watch(repostsProvider);
    final isReposted = repostsState.getRepostedOverride(post.id) ?? post.hasReposted;
    final sharesCount = repostsState.getCountOverride(post.id) ?? post.sharesCount;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SocialPost(
          userId: post.user.id,
          userName: post.user.displayName,
          userAvatarUrl: post.user.avatarUrl,
          content: post.content,
          imageUrl: post.imageUrl,
          likesCount: likesCount,
          commentsCount: post.commentsCount,
          sharesCount: sharesCount,
          isLiked: isLiked,
          isSaved: isSaved,
          isReposted: isReposted,
          isVerified: post.user.isVerified,
          price: price,
          onTap: () => context.push('/post/${post.id}'),
          onUserTap: () => context.push('/user/${post.user.id}'),
          onSave: () async {
            final user = ref.read(authControllerProvider).valueOrNull;
            if (user == null || user.isGuest) {
              if (context.mounted) {
                AppSnackbar.warning(context, 'Faça login para salvar');
              }
              return false;
            }
            return ref.read(savesProvider.notifier).toggleSave(
                  post.id,
                  initialIsSaved: post.isSaved,
                );
          },
          onLike: () async {
            final user = ref.read(authControllerProvider).valueOrNull;
            if (user == null || user.isGuest) {
              if (context.mounted) {
                AppSnackbar.warning(context, 'Faça login para curtir');
              }
              return false;
            }
            final success = await ref.read(likesProvider.notifier).toggleLike(
                  post.id,
                  initialIsLiked: post.isLiked,
                  initialCount: post.likesCount,
                );
            if (success && context.mounted) {
              final newLikesState = ref.read(likesProvider);
              ref.read(feedProvider.notifier).updatePostLike(
                    post.id,
                    newLikesState.getLikedOverride(post.id) ?? post.isLiked,
                    newLikesState.getCountOverride(post.id) ?? post.likesCount,
                  );
            }
            return success;
          },
          onRepost: () async {
            final user = ref.read(authControllerProvider).valueOrNull;
            if (user == null || user.isGuest) {
              if (context.mounted) {
                AppSnackbar.warning(context, 'Faça login para repostar');
              }
              return false;
            }
            final success = await ref.read(repostsProvider.notifier).toggleRepost(
                  post.id,
                  initialIsReposted: post.hasReposted,
                  initialCount: post.sharesCount,
                );
            if (success && context.mounted) {
              final newRepostsState = ref.read(repostsProvider);
              ref.read(feedProvider.notifier).updateSharesCount(
                    post.id,
                    newRepostsState.getCountOverride(post.id) ?? post.sharesCount,
                  );
            }
            return success;
          },
          onComment: () => context.push('/post/${post.id}/comments'),
          onShare: () {},
        ),
      ),
    );
  }
}
