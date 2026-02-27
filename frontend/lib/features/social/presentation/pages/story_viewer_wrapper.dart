import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_page.dart';

class StoryViewerWrapper extends ConsumerWidget {
  final String? indexParam;

  const StoryViewerWrapper({super.key, this.indexParam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return storiesAsync.when(
      data: (storiesResponse) {
        final stories = storiesResponse.stories;
        if (stories.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No stories available')),
          );
        }

        int initialIndex = 0;
        if (indexParam != null) {
          initialIndex = int.tryParse(indexParam!) ?? 0;
          if (initialIndex < 0 || initialIndex >= stories.length) {
            initialIndex = 0;
          }
        }

        return StoryViewerPage(
          stories: stories,
          initialIndex: initialIndex,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}
