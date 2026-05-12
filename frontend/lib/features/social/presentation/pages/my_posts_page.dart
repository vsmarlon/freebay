import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
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
    final postsAsync = ref.watch(userPostsProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Meus posts'),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: context.textPrimary,
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
                  const Icon(
                    Icons.grid_view_rounded,
                    size: 64,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum post ainda',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.mediumGray,
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
              return _buildPostTile(context, post);
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
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTile(BuildContext context, PostEntity post) {
    final content = post.content ?? '';
    final imageUrl = post.imageUrl;
    final isReposted = post.repostedAt != null;

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.surfaceMidColor,
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
                  color: AppColors.primaryPurple.withAlpha(204),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Reposted',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
}
