import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

final userPostsProvider =
    FutureProvider.family<List<PostEntity>, String>((ref, userId) async {
  final repository = SocialRepository();
  final result = await repository.getPostsByUser(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (posts) => posts,
  );
});

class MyPostsPage extends ConsumerWidget {
  final String userId;

  const MyPostsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(userPostsProvider(userId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Meus posts'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () => context.push('/create-post'),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 64,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum post ainda',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => context.push('/create-post'),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.brutalistGradient,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: AppColors.onPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Criar post',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostTile(context, post, isDark);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar posts',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTile(BuildContext context, PostEntity post, bool isDark) {
    final content = post.content ?? '';
    final imageUrl = post.imageUrl;

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
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
                          color: isDark ? AppColors.white : AppColors.darkGray,
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
    );
  }
}
