import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/shared/utils/media_url.dart';

class MyStoriesPage extends HookConsumerWidget {
  final String userId;

  const MyStoriesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(userStoriesProvider(userId));
    final hiddenStories = useState(<String>{});
    final currentUserId = ref.watch(authControllerProvider).value?.id;

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
                final visibleStories = stories
                    .where((story) => !hiddenStories.value.contains(story.id))
                    .toList();
                return Column(
                  children: [
                    BrutalistBreadcrumb(items: [...context.breadcrumbs]),
                    Expanded(
                      child: visibleStories.isEmpty
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
                                itemCount: visibleStories.length,
                                itemBuilder: (_, index) {
                                  final story = visibleStories[index];
                                  return _buildStoryTile(
                                    context,
                                    ref,
                                    story,
                                    hiddenStories,
                                    currentUserId == story.userId,
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
    ValueNotifier<Set<String>> hiddenStories,
    bool isOwner,
  ) {
    final now = DateTime.now();
    final expiry = story.expiresAt;
    final isExpired = expiry.isBefore(now);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storyAt(0)),
      onLongPress: isOwner
          ? () => _showDeleteDialog(context, ref, story, hiddenStories)
          : null,
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
                      image: NetworkImage(
                        story.imageUrl,
                        headers: mediaAuthHeaders(story.imageUrl),
                      ),
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
          if (story.audience == StoryAudience.closeFriends)
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(Icons.group, color: AppColors.success, size: 24),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    StoryEntity story,
    ValueNotifier<Set<String>> hiddenStories,
  ) {
    final repository = ref.read(socialRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.bgColor,
        title: Text(
          'Excluir história?',
          style: TextStyle(color: dialogContext.textPrimary),
        ),
        content: Text(
          'Você terá alguns segundos para desfazer.',
          style: TextStyle(color: dialogContext.textSecondary),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.pop(dialogContext),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Cancelar',
                style: TextStyle(color: dialogContext.textPrimary),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(dialogContext);
              hiddenStories.value = {...hiddenStories.value, story.id};
              AppSnackbar.undoable(
                context,
                message: 'História será excluída.',
                onUndo: () {
                  if (context.mounted) {
                    hiddenStories.value = {...hiddenStories.value}
                      ..remove(story.id);
                  }
                },
                onCommit: () async {
                  final result = await repository.deleteStory(story.id);
                  result.fold(
                    (failure) {
                      if (context.mounted) {
                        hiddenStories.value = {...hiddenStories.value}
                          ..remove(story.id);
                      }
                      if (messenger.mounted) {
                        AppSnackbar.errorOnMessenger(
                          messenger,
                          failure.message,
                        );
                      }
                    },
                    (_) {
                      container.invalidate(userStoriesProvider(userId));
                      container.invalidate(storiesProvider);
                    },
                  );
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
