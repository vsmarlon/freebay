import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class StoriesRow extends ConsumerWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final groups = storiesAsync.value?.groups ?? [];

    return _buildRow(
      context,
      ref,
      groups,
      isLoading: storiesAsync.isLoading && groups.isEmpty,
    );
  }

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref,
    List<StoryGroupEntity> groups, {
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 60 + 30 * MediaQuery.textScalerOf(context).scale(1),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _AddStoryItem();
          }
          final group = groups[index - 1];
          return _StoryItem(
            group: group,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.storyAt(index - 1));
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
    final strings = l10n(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.createStory);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryContainer,
                size: 24,
              ),
            ),
            Spacing.vXs,
            SizedBox(
              width: 140,
              child: Text(
                strings.feedCreateStory,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                maxLines: 2,
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
  final StoryGroupEntity group;
  final VoidCallback onTap;

  const _StoryItem({required this.group, required this.onTap});

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
                  color:
                      group.stories.any(
                        (story) => story.audience == StoryAudience.closeFriends,
                      )
                      ? AppColors.success
                      : AppColors.primaryContainer,
                  width: 2,
                ),
                image: group.user.avatarUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          group.user.avatarUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: context.surfaceColor,
              ),
              child: group.user.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.outline, size: 24)
                  : null,
            ),
            Spacing.vXs,
            SizedBox(
              width: 56,
              child: Text(
                group.user.displayName,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
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
