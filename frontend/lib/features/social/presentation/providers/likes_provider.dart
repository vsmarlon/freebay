import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class LikesState {
  /// Map of post IDs to their liked status override (null means use entity value)
  final Map<String, bool> likedOverrides;
  /// Map of post IDs to their like count override (null means use entity value)
  final Map<String, int> countOverrides;

  const LikesState({
    this.likedOverrides = const {},
    this.countOverrides = const {},
  });

  LikesState copyWith({
    Map<String, bool>? likedOverrides,
    Map<String, int>? countOverrides,
  }) {
    return LikesState(
      likedOverrides: likedOverrides ?? this.likedOverrides,
      countOverrides: countOverrides ?? this.countOverrides,
    );
  }

  bool? getLikedOverride(String postId) => likedOverrides[postId];
  int? getCountOverride(String postId) => countOverrides[postId];
}

class LikesNotifier extends StateNotifier<LikesState> {
  final ISocialRepository _repository;

  LikesNotifier(this._repository) : super(const LikesState());

  /// Toggles like status. If no override exists, it uses initial values from the entity.
  Future<bool> toggleLike(String postId, {required bool initialIsLiked, required int initialCount}) async {
    final currentLiked = state.likedOverrides[postId] ?? initialIsLiked;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsLiked = !currentLiked;
    final newCount = newIsLiked ? currentCount + 1 : currentCount - 1;

    // Apply optimistic update
    state = state.copyWith(
      likedOverrides: {...state.likedOverrides, postId: newIsLiked},
      countOverrides: {...state.countOverrides, postId: newCount},
    );

    try {
      final result = newIsLiked 
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);

      if (result.isLeft()) {
        // Rollback on failure
        state = state.copyWith(
          likedOverrides: {...state.likedOverrides, postId: currentLiked},
          countOverrides: {...state.countOverrides, postId: currentCount},
        );
        return false;
      }
      return true;
    } catch (e) {
      // Rollback on exception
      state = state.copyWith(
        likedOverrides: {...state.likedOverrides, postId: currentLiked},
        countOverrides: {...state.countOverrides, postId: currentCount},
      );
      return false;
    }
  }
}

final likesProvider = StateNotifierProvider<LikesNotifier, LikesState>((ref) {
  final repository = ref.read(socialRepositoryProvider);
  return LikesNotifier(repository);
});
