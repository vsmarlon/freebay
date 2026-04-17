import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';

final userStoriesProvider =
    FutureProvider.family<List<StoryEntity>, String>((ref, userId) async {
  final repository = SocialRepository();
  final result = await repository.getUserStories(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stories) => stories,
  );
});

class MyStoriesPage extends ConsumerWidget {
  final String userId;

  const MyStoriesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storiesAsync = ref.watch(userStoriesProvider(userId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Minhas histórias'),
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
            onPressed: () => context.push('/create-story'),
          ),
        ],
      ),
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma história',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => context.push('/create-story'),
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
                            'Criar história',
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
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _buildStoryTile(context, ref, story, isDark);
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
                'Erro ao carregar histórias',
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

  Widget _buildStoryTile(
      BuildContext context, WidgetRef ref, StoryEntity story, bool isDark) {
    final now = DateTime.now();
    final expiry = story.expiresAt;
    final isExpired = expiry.isBefore(now);

    return GestureDetector(
      onTap: () => context.push('/story?index=0'),
      onLongPress: () => _showDeleteDialog(context, ref, story, isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              image: story.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(story.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
            ),
            child: story.imageUrl.isEmpty
                ? const Icon(Icons.image, color: AppColors.mediumGray)
                : null,
          ),
          if (isExpired)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.access_time,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, StoryEntity story, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        title: Text(
          'Excluir história?',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Cancelar',
                style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.darkGray),
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              final repository = SocialRepository();
              await repository.deleteStory(story.id);
              ref.invalidate(userStoriesProvider(userId));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Excluir',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
