import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/likes_provider.dart';
import 'package:freebay/features/social/presentation/providers/saves_provider.dart';
import 'package:freebay/features/social/presentation/providers/reposts_provider.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class FeedPostItem extends ConsumerStatefulWidget {
  final PostEntity post;
  final VoidCallback? onUnsaved;

  const FeedPostItem({super.key, required this.post, this.onUnsaved});

  @override
  ConsumerState<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends ConsumerState<FeedPostItem> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final strings = l10n(context);
    final routePath = GoRouter.maybeOf(context)?.state.uri.path;
    final canHeroToPostDetail =
        routePath == AppRoutes.feed ||
        routePath == AppRoutes.profileLiked ||
        routePath == AppRoutes.profileSaved;
    final price = post.product?.price != null && post.product!.price > 0
        ? post.product!.price / 100
        : null;

    final isLiked =
        ref.watch(likesProvider.select((s) => s.getLikedOverride(post.id))) ??
        post.isLiked;
    final likesCount =
        ref.watch(likesProvider.select((s) => s.getCountOverride(post.id))) ??
        post.likesCount;

    final isSaved =
        ref.watch(savesProvider.select((s) => s.getSavedOverride(post.id))) ??
        post.isSaved;

    final isReposted =
        ref.watch(
          repostsProvider.select((s) => s.getRepostedOverride(post.id)),
        ) ??
        post.hasReposted;
    final sharesCount =
        ref.watch(repostsProvider.select((s) => s.getCountOverride(post.id))) ??
        post.sharesCount;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.base,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.repostedBy != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  strings.feedRepostedBy(post.repostedBy!.displayNameOrDefault),
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
            SocialPost(
              userId: post.user.id,
              userName: post.user.displayNameOrDefault,
              userAvatarUrl: post.user.avatarUrl,
              userAvatarBlurHash: post.user.avatarBlurHash,
              content: post.content,
              imageUrl: post.imageUrl,
              imageBlurHash: post.audience == PostAudience.everyone
                  ? post.imageBlurHash
                  : null,
              likesCount: likesCount,
              commentsCount: post.commentsCount,
              sharesCount: sharesCount,
              isLiked: isLiked,
              isSaved: isSaved,
              isReposted: isReposted,
              isVerified: post.user.isVerified,
              createdAt: post.createdAt,
              heroTag: canHeroToPostDetail ? 'post-media-${post.id}' : null,
              price: price,
              isSelling: post.type == PostType.product,
              isCloseFriends: post.audience == PostAudience.closeFriends,
              closeFriendsLabel: strings.feedAudienceCloseFriends,
              onTap: () => context.push(AppRoutes.postPath(post.id)),
              onUserTap: () => context.push(AppRoutes.userPath(post.user.id)),
              onSave: () async {
                final user = ref.read(authControllerProvider).value;
                if (user == null) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, strings.feedLoginToSave);
                  }
                  return false;
                }
                final success = await ref
                    .read(savesProvider.notifier)
                    .toggleSave(post.id, initialIsSaved: post.isSaved);
                if (success && post.isSaved) widget.onUnsaved?.call();
                return success;
              },
              onLike: () async {
                final user = ref.read(authControllerProvider).value;
                if (user == null) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, strings.feedLoginToLike);
                  }
                  return false;
                }
                final success = await ref
                    .read(likesProvider.notifier)
                    .toggleLike(
                      post.id,
                      initialIsLiked: post.isLiked,
                      initialCount: post.likesCount,
                    );
                return success;
              },
              onRepost: () async {
                final user = ref.read(authControllerProvider).value;
                if (user == null) {
                  if (context.mounted) {
                    AppSnackbar.warning(context, strings.feedLoginToRepost);
                  }
                  return false;
                }
                final success = await ref
                    .read(repostsProvider.notifier)
                    .toggleRepost(
                      post.id,
                      initialIsReposted: post.hasReposted,
                      initialCount: post.sharesCount,
                    );
                if (success && context.mounted) {
                  ref.invalidate(
                    profileTimelineProvider(
                      user.id,
                      kind: 'reposts',
                      viewerId: user.id,
                    ),
                  );
                }
                return success;
              },
              onComment: () => context.push(AppRoutes.postPath(post.id)),
            ),
          ],
        ),
      ),
    );
  }
}
