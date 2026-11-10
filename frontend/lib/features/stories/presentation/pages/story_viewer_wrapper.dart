import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/stories/presentation/pages/story_viewer_page.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/stories/presentation/providers/story_highlight_provider.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

final freshViewerStoriesProvider = FutureProvider.autoDispose<StoriesResponse>((
  ref,
) async {
  final result = await ref.read(storiesRepositoryProvider).getStories();
  return result.fold((failure) => throw failure, (stories) => stories);
});

/// Viewer location for [storyId]. The `index` query parameter carries the story
/// id; a numeric value still works for older links (see [StoryViewerWrapper]).
String storyViewerLocation(String storyId) =>
    '${AppRoutes.story}?index=${Uri.encodeComponent(storyId)}';

class StoryViewerWrapper extends ConsumerWidget {
  final String? indexParam;

  const StoryViewerWrapper({super.key, this.indexParam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final storiesAsync = ref.watch(freshViewerStoriesProvider);

    return storiesAsync.when(
      data: (storiesResponse) {
        final groups = storiesResponse.groups;
        if (groups.isEmpty) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.auto_awesome,
              title: strings.feedNoStories,
              subtitle: strings.feedNoStoriesBody,
            ),
          );
        }

        int initialIndex = 0;
        final target = indexParam;
        if (target != null && target.isNotEmpty) {
          // Legacy links carried a group position; new ones carry the story id,
          // resolved here against the list the viewer actually shows.
          final legacyIndex = int.tryParse(target);
          final resolved =
              legacyIndex ??
              groups.indexWhere(
                (group) => group.stories.any((story) => story.id == target),
              );
          initialIndex = resolved < 0 || resolved >= groups.length
              ? 0
              : resolved;
        }

        return StoryViewerPage(groups: groups, initialGroupIndex: initialIndex);
      },
      loading: () => const SkeletonPage(
        child: Column(
          children: [
            ShimmerBlock(height: 4),
            SizedBox(height: 12),
            Row(
              children: [
                ShimmerBlock(width: 40, height: 40),
                SizedBox(width: 12),
                ShimmerBlock(height: 14, width: 120),
              ],
            ),
            SizedBox(height: 40),
            ShimmerBlock(height: 400),
          ],
        ),
      ),
      error: (err, _) =>
          Scaffold(body: EmptyState.error(message: userMessageOf(err))),
    );
  }
}

class HighlightStoryViewerWrapper extends ConsumerWidget {
  const HighlightStoryViewerWrapper({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(storyHighlightProvider(id))
      .when(
        data: (highlight) => StoryViewerPage(groups: [highlight.group]),
        loading: () => const Scaffold(
          body: SkeletonPage(child: ShimmerBlock(height: 400)),
        ),
        error: (err, _) =>
            Scaffold(body: EmptyState.error(message: userMessageOf(err))),
      );
}
