import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class LikesState {
  final Set<String> likedPostIds;
  final Map<String, int> likeCounts;

  const LikesState({
    this.likedPostIds = const {},
    this.likeCounts = const {},
  });

  LikesState copyWith({
    Set<String>? likedPostIds,
    Map<String, int>? likeCounts,
  }) {
    return LikesState(
      likedPostIds: likedPostIds ?? this.likedPostIds,
      likeCounts: likeCounts ?? this.likeCounts,
    );
  }

  bool isLiked(String postId) => likedPostIds.contains(postId);
  int getLikeCount(String postId) => likeCounts[postId] ?? 0;
}

class LikesNotifier extends StateNotifier<LikesState> {
  final ISocialRepository _repository;

  LikesNotifier(this._repository) : super(const LikesState());

  void initializeFromPosts(List<dynamic> posts) {
    final likedIds = <String>{};
    final counts = <String, int>{};

    for (final post in posts) {
      if (post.isLiked == true) {
        likedIds.add(post.id);
      }
      counts[post.id] = post.likesCount ?? 0;
    }

    state = state.copyWith(
      likedPostIds: likedIds,
      likeCounts: counts,
    );
  }

  void initializeSinglePost(String postId, bool isLiked, int likeCount) {
    final newLikedIds = Set<String>.from(state.likedPostIds);
    final newCounts = Map<String, int>.from(state.likeCounts);

    if (isLiked) {
      newLikedIds.add(postId);
    } else {
      newLikedIds.remove(postId);
    }
    newCounts[postId] = likeCount;

    state = state.copyWith(
      likedPostIds: newLikedIds,
      likeCounts: newCounts,
    );
  }

  Future<bool> toggleLike(String postId) async {
    final wasLiked = state.isLiked(postId);
    final previousCount = state.getLikeCount(postId);

    final newLikedIds = Set<String>.from(state.likedPostIds);
    final newCounts = Map<String, int>.from(state.likeCounts);

    if (wasLiked) {
      newLikedIds.remove(postId);
      newCounts[postId] = previousCount - 1;
    } else {
      newLikedIds.add(postId);
      newCounts[postId] = previousCount + 1;
    }

    state = state.copyWith(
      likedPostIds: newLikedIds,
      likeCounts: newCounts,
    );

    try {
      if (wasLiked) {
        final result = await _repository.unlikePost(postId);
        if (result.isLeft()) {
          state = state.copyWith(
            likedPostIds: wasLiked
                ? {...state.likedPostIds, postId}
                : state.likedPostIds.difference({postId}),
            likeCounts: {...state.likeCounts, postId: previousCount},
          );
          return false;
        }
      } else {
        final result = await _repository.likePost(postId);
        if (result.isLeft()) {
          state = state.copyWith(
            likedPostIds: wasLiked
                ? {...state.likedPostIds, postId}
                : state.likedPostIds.difference({postId}),
            likeCounts: {...state.likeCounts, postId: previousCount},
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        likedPostIds: wasLiked
            ? {...state.likedPostIds, postId}
            : state.likedPostIds.difference({postId}),
        likeCounts: {...state.likeCounts, postId: previousCount},
      );
      return false;
    }
  }

  bool isLiked(String postId) => state.isLiked(postId);
  int getLikeCount(String postId) => state.getLikeCount(postId);
}

final likesProvider = StateNotifierProvider<LikesNotifier, LikesState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return LikesNotifier(repository);
});
