import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/page_header.dart';

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
    final isDark = context.isDark;
    final storiesAsync = ref.watch(userStoriesProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'MINHAS HISTÓRIAS',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
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
          Expanded(
            child: storiesAsync.when(
              data: (stories) {
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: [
                      BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
                      const BreadcrumbItem(label: 'Minhas Hist\u00f3rias'),
                    ]),
                    Expanded(
                      child: stories.isEmpty
                          ? EmptyState(
                              icon: Icons.auto_awesome,
                              title: 'NENHUMA HIST\u00d3RIA',
                              subtitle: 'Crie sua primeira hist\u00f3ria!',
                              action: InkWell(
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
                                      Spacing.hSm,
                                      Text(
                                        'Criar hist\u00f3ria',
                                        style: TextStyle(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(userStoriesProvider(userId));
                              },
                              child: GridView.builder(
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
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryContainer),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    Spacing.vMd,
                    Text(
                      'Erro ao carregar hist\u00f3rias',
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
              border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.15), width: 2),
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
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.access_time,
                  color: AppColors.onPrimary,
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
