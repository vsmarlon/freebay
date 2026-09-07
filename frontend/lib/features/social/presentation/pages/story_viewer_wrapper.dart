import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_page.dart';
import 'package:freebay/core/ui.dart';

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
            body: EmptyState(
              icon: Icons.auto_awesome,
              title: 'NENHUMA HISTÓRIA',
              subtitle: 'No momento não há histórias disponíveis.',
            ),
          );
        }

        int initialIndex = 0;
        if (indexParam != null) {
          initialIndex = int.tryParse(indexParam!) ?? 0;
          if (initialIndex < 0 || initialIndex >= stories.length) {
            initialIndex = 0;
          }
        }

        return StoryViewerPage(stories: stories, initialIndex: initialIndex);
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
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
