import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

final storyArchiveProvider = FutureProvider.autoDispose<List<StoryEntity>>((
  ref,
) async {
  ref.watch(authControllerProvider);
  final result = await ref.read(socialRepositoryProvider).getStoryArchive();
  return result.fold((failure) => throw failure, (stories) => stories);
});

final storyHighlightsProvider = FutureProvider.autoDispose
    .family<List<StoryHighlightEntity>, String>((ref, userId) async {
      ref.watch(authControllerProvider.select((state) => state.value?.id));
      final result = await ref
          .read(socialRepositoryProvider)
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
          .read(socialRepositoryProvider)
          .getStoryHighlight(id);
      return result.fold((failure) => throw failure, (highlight) => highlight);
    });
