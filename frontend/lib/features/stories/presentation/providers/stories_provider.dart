import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/data/repositories/stories_repository.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository();
});

final storiesProvider = FutureProvider<StoriesResponse>((ref) async {
  final result = await ref.watch(storiesRepositoryProvider).getStories();
  return result.fold((failure) => throw failure, (stories) => stories);
});

final userStoriesProvider = FutureProvider.family<List<StoryEntity>, String>((
  ref,
  userId,
) async {
  final result = await ref
      .watch(storiesRepositoryProvider)
      .getUserStories(userId);
  return result.fold((failure) => throw failure, (stories) => stories);
});

void invalidateStoryConsumers(WidgetRef ref, String userId) {
  ref.invalidate(storiesProvider);
  ref.invalidate(userStoriesProvider(userId));
}
