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

final userPostsProvider = FutureProvider.family<List<PostEntity>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getPostsByUser(userId);
  return result.fold((failure) => throw failure, (page) => page.items);
});

class MyPostsPage extends HookConsumerWidget {
  final String userId;

  const MyPostsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));
    final hiddenPosts = useState(<String>{});
    final currentUserId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'MEUS POSTS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
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
              data: (posts) {
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
                              title: 'NENHUM POST AINDA',
                              subtitle: 'Crie seu primeiro post!',
                              action: AppButton(
                                label: 'Criar post',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.push(AppRoutes.createPost),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(userPostsProvider(userId));
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                    ),
                                itemCount: visiblePosts.length,
                                itemBuilder: (_, index) {
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
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    Spacing.vMd,
                    Text(
                      'Erro ao carregar posts',
                      style: TextStyle(color: context.textPrimary),
                    ),
                  ],
                ),
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
    final repository = ref.read(socialRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    showBrutalistSheet(
      context: context,
      title: 'PUBLICAÇÃO',
      builder: (sheetContext) => AppButton(
        label: 'Excluir post',
        variant: AppButtonVariant.danger,
        onPressed: () {
          Navigator.pop(sheetContext);
          hiddenPosts.value = {...hiddenPosts.value, post.id};
          AppSnackbar.undoable(
            context,
            message: 'Post será excluído.',
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
                  container.invalidate(userPostsProvider(userId));
                  container.invalidate(profileTimelineProvider(userId));
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.repeat, size: 10, color: AppColors.onPrimary),
                    SizedBox(width: 2),
                    Text(
                      'Reposted',
                      style: TextStyle(
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
