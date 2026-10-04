import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';

final storyArchiveProvider = FutureProvider.autoDispose<List<StoryEntity>>((
  ref,
) async {
  ref.watch(authControllerProvider);
  final result = await ref.read(storiesRepositoryProvider).getStoryArchive();
  return result.fold((failure) => throw failure, (stories) => stories);
});

final storyHighlightsProvider = FutureProvider.autoDispose
    .family<List<StoryHighlightEntity>, String>((ref, userId) async {
      ref.watch(authControllerProvider.select((state) => state.value?.id));
      final result = await ref
          .read(storiesRepositoryProvider)
          .getStoryHighlights(userId);
      return result.fold(
        (failure) => throw failure,
        (highlights) => highlights,
      );
    });

final storyHighlightProvider = FutureProvider.autoDispose
    .family<StoryHighlightEntity, String>((ref, id) async {
      ref.watch(authControllerProvider.select((state) => state.value?.id));
      final result = await ref
          .read(storiesRepositoryProvider)
          .getStoryHighlight(id);
      return result.fold((failure) => throw failure, (highlight) => highlight);
    });
