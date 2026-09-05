import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

final likedPostsProvider = FutureProvider<List<PostEntity>>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getLikedPosts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (posts) => posts,
  );
});

class LikedPostsPage extends ConsumerWidget {
  const LikedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final postsAsync = ref.watch(likedPostsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'POSTS CURTIDOS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: [...context.breadcrumbs]),
                    Expanded(
                      child: posts.isEmpty
                          ? const EmptyState(
                              icon: Icons.favorite_border,
                              title: 'NENHUM POST CURTIDO',
                              subtitle: 'Curtidas em posts aparecerão aqui.',
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(likedPostsProvider);
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                    ),
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  return _buildPostTile(context, post, isDark);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, _) => const ShimmerBlock(height: 120),
                  physics: const NeverScrollableScrollPhysics(),
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
                      'Erro ao carregar posts curtidos',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
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

  Widget _buildPostTile(BuildContext context, PostEntity post, bool isDark) {
    final imageUrl = post.imageUrl;

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
          border: Border.all(
            color: AppColors.onSurface.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                memCacheHeight: 300,
                placeholder: (_, _) => Container(
                  color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
                ),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.image, color: AppColors.mediumGray),
              )
            : post.content != null && post.content!.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    post.content!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            : const Icon(Icons.article_outlined, color: AppColors.mediumGray),
      ),
    );
  }
}
