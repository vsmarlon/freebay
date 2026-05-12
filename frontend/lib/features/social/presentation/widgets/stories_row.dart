import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class StoriesRow extends ConsumerWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    return storiesAsync.when(
      data: (response) => _buildRow(context, ref, response.stories),
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(height: 100),
    );
  }

  Widget _buildRow(
      BuildContext context, WidgetRef ref, List<StoryEntity> stories) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _AddStoryItem();
          }
          final story = stories[index - 1];
          return _StoryItem(
            story: story,
            onTap: () {
              HapticFeedback.lightImpact();
              final current =
                  ref.read(storiesProvider).valueOrNull?.stories ?? [];
              if (current.isNotEmpty) {
                final storyIndex =
                    current.indexWhere((s) => s.id == story.id);
                context.push('/story?index=$storyIndex');
              }
            },
          );
        },
      ),
    );
  }
}

class _AddStoryItem extends StatelessWidget {
  const _AddStoryItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/create-story');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                'Adicionar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final StoryEntity story;
  final VoidCallback onTap;

  const _StoryItem({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: story.isViewed
                      ? AppColors.outline
                      : AppColors.primaryContainer,
                  width: 2,
                ),
                image: story.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(story.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: context.surfaceColor,
              ),
              child: story.imageUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppColors.outline,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                story.user.displayName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
