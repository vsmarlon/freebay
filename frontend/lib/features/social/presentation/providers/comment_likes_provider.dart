import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class CommentLikesState {
  /// Map of comment IDs to their liked status override (null means use entity value)
  final Map<String, bool> likedOverrides;
  /// Map of comment IDs to their like count override (null means use entity value)
  final Map<String, int> countOverrides;

  const CommentLikesState({
    this.likedOverrides = const {},
    this.countOverrides = const {},
  });

  CommentLikesState copyWith({
    Map<String, bool>? likedOverrides,
    Map<String, int>? countOverrides,
  }) {
    return CommentLikesState(
      likedOverrides: likedOverrides ?? this.likedOverrides,
      countOverrides: countOverrides ?? this.countOverrides,
    );
  }

  bool? getLikedOverride(String commentId) => likedOverrides[commentId];
  int? getCountOverride(String commentId) => countOverrides[commentId];
}

class CommentLikesNotifier extends StateNotifier<CommentLikesState> {
  final ISocialRepository _repository;

  CommentLikesNotifier(this._repository) : super(const CommentLikesState());

  /// Toggles like status. If no override exists, it uses initial values from the entity.
  Future<bool> toggleLike(String commentId, {required bool initialIsLiked, required int initialCount}) async {
    final currentLiked = state.likedOverrides[commentId] ?? initialIsLiked;
    final currentCount = state.countOverrides[commentId] ?? initialCount;

    final newIsLiked = !currentLiked;
    final newCount = newIsLiked ? currentCount + 1 : currentCount - 1;

    // Apply optimistic update
    state = state.copyWith(
      likedOverrides: {...state.likedOverrides, commentId: newIsLiked},
      countOverrides: {...state.countOverrides, commentId: newCount},
    );

    try {
      final result = newIsLiked 
          ? await _repository.likeComment(commentId)
          : await _repository.unlikeComment(commentId);

      if (result.isLeft()) {
        // Rollback on failure
        state = state.copyWith(
          likedOverrides: {...state.likedOverrides, commentId: currentLiked},
          countOverrides: {...state.countOverrides, commentId: currentCount},
        );
        return false;
      }
      return true;
    } catch (e) {
      // Rollback on exception
      state = state.copyWith(
        likedOverrides: {...state.likedOverrides, commentId: currentLiked},
        countOverrides: {...state.countOverrides, commentId: currentCount},
      );
      return false;
    }
  }
}

final commentLikesProvider =
    StateNotifierProvider<CommentLikesNotifier, CommentLikesState>((ref) {
  final repository = ref.read(socialRepositoryProvider);
  return CommentLikesNotifier(repository);
});
