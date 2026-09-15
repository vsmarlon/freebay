import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/core/router/navigation_tracker.dart';

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
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: context.textPrimary),
                onPressed: () => context.push(AppRoutes.createStory),
              ),
            ],
          ),
          Expanded(
            child: storiesAsync.when(
              data: (stories) {
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: [...context.breadcrumbs]),
                    Expanded(
                      child: stories.isEmpty
                          ? EmptyState(
                              icon: Icons.auto_awesome,
                              title: 'NENHUMA HIST\u00d3RIA',
                              subtitle: 'Crie sua primeira hist\u00f3ria!',
                              action: AppButton(
                                label: 'Criar hist\u00f3ria',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.push(AppRoutes.createStory),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                ref.invalidate(userStoriesProvider(userId));
                              },
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.7,
                                    ),
                                itemCount: stories.length,
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  return _buildStoryTile(
                                    context,
                                    ref,
                                    story,
                                    isDark,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    _StoryRingSkeleton(),
                    SizedBox(width: 16),
                    _StoryRingSkeleton(),
                    SizedBox(width: 16),
                    _StoryRingSkeleton(),
                    SizedBox(width: 16),
                    _StoryRingSkeleton(),
                    SizedBox(width: 16),
                    _StoryRingSkeleton(),
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
                      'Erro ao carregar hist\u00f3rias',
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

  Widget _buildStoryTile(
    BuildContext context,
    WidgetRef ref,
    StoryEntity story,
    bool isDark,
  ) {
    final now = DateTime.now();
    final expiry = story.expiresAt;
    final isExpired = expiry.isBefore(now);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyAt(0)),
      onLongPress: () => _showDeleteDialog(context, ref, story, isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.onSurface.withValues(alpha: 0.15),
                width: 2,
              ),
              image: story.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(story.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: context.bgColor,
            ),
            child: story.imageUrl.isEmpty
                ? const Icon(Icons.image, color: AppColors.mediumGray)
                : null,
          ),
          if (isExpired)
            Container(
              decoration: BoxDecoration(
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: Icon(Icons.access_time, color: AppColors.onPrimary),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    StoryEntity story,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgColor,
        title: Text(
          'Excluir história?',
          style: TextStyle(color: context.textPrimary),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.textPrimary),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              AppSnackbar.undoable(
                context,
                message: 'Story apagado.',
                onUndo: () {},
                onCommit: () async {
                  await ref
                      .read(socialRepositoryProvider)
                      .deleteStory(story.id);
                  ref.invalidate(userStoriesProvider(userId));
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Excluir', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryRingSkeleton extends StatelessWidget {
  const _StoryRingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBlock(width: 64, height: 64),
        SizedBox(height: 8),
        ShimmerBlock(height: 12, width: 50),
      ],
    );
  }
}
