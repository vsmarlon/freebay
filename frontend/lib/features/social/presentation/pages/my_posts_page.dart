import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/models/cursor_page.dart';

final userPostsProvider =
    FutureProvider.family<CursorPage<PostEntity>, String?>((ref, userId) async {
      if (userId == null) return const CursorPage.empty();
      final repository = ref.watch(socialRepositoryProvider);
      final result = await repository.getPostsByUser(userId);
      return result.fold((failure) => throw failure, (page) => page);
    });

class MyPostsPage extends HookConsumerWidget {
  final String userId;

  const MyPostsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final authUserId = ref.watch(authControllerProvider).value?.id;
    final targetUserId = userId == 'me' ? authUserId : userId;
    final postsAsync = ref.watch(userPostsProvider(targetUserId));
    final hiddenPosts = useState(<String>{});
    final accumulated = useState(<PostEntity>[]);
    final ownerGeneration = useRef(0);
    final cursor = useState<String?>(null);
    final hasMore = useState(true);
    final loadingMore = useState(false);
    final loadError = useState<String?>(null);
    final currentUserId = authUserId;

    useEffect(() {
      ownerGeneration.value++;
      hiddenPosts.value = {};
      accumulated.value = [];
      cursor.value = null;
      hasMore.value = true;
      loadingMore.value = false;
      loadError.value = null;
      return null;
    }, [targetUserId]);

    useEffect(() {
      final firstPage = postsAsync.asData?.value;
      if (firstPage != null) {
        accumulated.value = firstPage.items;
        cursor.value = firstPage.nextCursor;
        hasMore.value = firstPage.hasMore && firstPage.nextCursor != null;
      }
      return null;
    }, [postsAsync]);

    Future<void> loadMore() async {
      if (targetUserId == null ||
          loadingMore.value ||
          !hasMore.value ||
          cursor.value == null) {
        return;
      }
      final requestGeneration = ownerGeneration.value;
      loadingMore.value = true;
      loadError.value = null;
      final result = await ref
          .read(socialRepositoryProvider)
          .getPostsByUser(targetUserId, cursor: cursor.value);
      if (!context.mounted || requestGeneration != ownerGeneration.value) {
        return;
      }
      result.fold((failure) => loadError.value = failure.message, (page) {
        accumulated.value = [...accumulated.value, ...page.items];
        cursor.value = page.nextCursor;
        hasMore.value = page.hasMore && page.nextCursor != null;
      });
      loadingMore.value = false;
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: strings.feedMyPostsTitle,
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              semanticLabel: strings.accessibilityBack,
              onTap: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: context.textPrimary),
                onPressed: () => context.push(AppRoutes.createPost),
              ),
            ],
          ),
          Expanded(
            child: postsAsync.when(
              data: (page) {
                final posts = accumulated.value.isEmpty
                    ? page.items
                    : accumulated.value;
                final visiblePosts = posts
                    .where((post) => !hiddenPosts.value.contains(post.id))
                    .toList();
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: [...context.breadcrumbs]),
                    Expanded(
                      child: visiblePosts.isEmpty
                          ? EmptyState(
                              icon: Icons.grid_view,
                              title: strings.profileNoPosts,
                              subtitle: strings.feedNoPostsBody,
                              action: AppButton(
                                label: strings.feedCreatePost,
                                icon: Icons.add,
                                onPressed: () =>
                                    context.push(AppRoutes.createPost),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ownerGeneration.value++;
                                accumulated.value = [];
                                cursor.value = null;
                                hasMore.value = true;
                                loadingMore.value = false;
                                loadError.value = null;
                                ref.invalidate(userPostsProvider(targetUserId));
                              },
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification.metrics.extentAfter < 300) {
                                    loadMore();
                                  }
                                  return false;
                                },
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                  itemCount:
                                      visiblePosts.length +
                                      (loadingMore.value ||
                                              loadError.value != null
                                          ? 1
                                          : 0),
                                  itemBuilder: (_, index) {
                                    if (index == visiblePosts.length) {
                                      return Center(
                                        child: loadError.value != null
                                            ? AppButton(
                                                label: strings.commonRetry,
                                                onPressed: loadMore,
                                              )
                                            : const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: ShimmerBlock(height: 72),
                                              ),
                                      );
                                    }
                                    final post = visiblePosts[index];
                                    return _buildPostTile(
                                      context,
                                      ref,
                                      post,
                                      hiddenPosts,
                                      currentUserId == post.userId &&
                                          post.repostedAt == null,
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                        SizedBox(width: 4),
                        Expanded(child: ShimmerBlock(height: 120)),
                      ],
                    ),
                  ],
                ),
              ),
              error: (err, _) => EmptyState.error(
                message: strings.commonError,
                onRetry: () => ref.invalidate(userPostsProvider(targetUserId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PostEntity post,
    ValueNotifier<Set<String>> hiddenPosts,
  ) {
    final strings = l10n(context);
    final repository = ref.read(socialRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    showBrutalistSheet(
      context: context,
      title: strings.feedPostTitle,
      builder: (sheetContext) => AppButton(
        label: strings.feedDeletePost,
        variant: AppButtonVariant.danger,
        onPressed: () {
          Navigator.pop(sheetContext);
          hiddenPosts.value = {...hiddenPosts.value, post.id};
          AppSnackbar.undoable(
            context,
            message: strings.feedPostDeletePending,
            onUndo: () {
              if (context.mounted) {
                hiddenPosts.value = {...hiddenPosts.value}..remove(post.id);
              }
            },
            onCommit: () async {
              final result = await repository.deletePost(post.id);
              result.fold(
                (failure) {
                  if (context.mounted) {
                    hiddenPosts.value = {...hiddenPosts.value}..remove(post.id);
                  }
                  if (messenger.mounted) {
                    AppSnackbar.errorOnMessenger(messenger, failure.message);
                  }
                },
                (_) {
                  container.invalidate(userPostsProvider(post.userId));
                  container.invalidate(
                    profileTimelineProvider(
                      post.userId,
                      kind: post.type == PostType.product
                          ? 'products'
                          : 'posts',
                      viewerId: userId,
                    ),
                  );
                  container.read(feedProvider.notifier).removePost(post.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostTile(
    BuildContext context,
    WidgetRef ref,
    PostEntity post,
    ValueNotifier<Set<String>> hiddenPosts,
    bool isOwner,
  ) {
    final content = post.content ?? '';
    final imageUrl = post.imageUrl;
    final isReposted = post.repostedAt != null;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.postPath(post.id)),
      onLongPress: isOwner
          ? () => _confirmDelete(context, ref, post, hiddenPosts)
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.surfaceMidColor,
              border: Border.all(
                color: AppColors.onSurface.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? isPrivateMedia(imageUrl)
                      ? Image.network(
                          imageUrl,
                          headers: mediaAuthHeaders(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image,
                            color: AppColors.mediumGray,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          memCacheHeight: 300,
                          placeholder: (_, _) =>
                              Container(color: context.surfaceMidColor),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.image,
                            color: AppColors.mediumGray,
                          ),
                        )
                : content.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.article_outlined,
                    color: AppColors.mediumGray,
                  ),
          ),
          if (isReposted)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(204),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat,
                      size: 10,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      l10n(context).feedRepostedBadge,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (post.audience == PostAudience.closeFriends)
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(Icons.group, color: AppColors.success, size: 22),
            ),
        ],
      ),
    );
  }
}
