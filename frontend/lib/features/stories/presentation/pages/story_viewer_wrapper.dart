import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/stories/presentation/pages/story_viewer_page.dart';
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
        if (indexParam != null) {
          initialIndex = int.tryParse(indexParam!) ?? 0;
          if (initialIndex < 0 || initialIndex >= groups.length) {
            initialIndex = 0;
          }
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
