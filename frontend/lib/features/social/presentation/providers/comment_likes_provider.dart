import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class CommentLikesState {
  final Set<String> likedCommentIds;
  final Map<String, int> likeCounts;

  const CommentLikesState({
    this.likedCommentIds = const {},
    this.likeCounts = const {},
  });

  CommentLikesState copyWith({
    Set<String>? likedCommentIds,
    Map<String, int>? likeCounts,
  }) {
    return CommentLikesState(
      likedCommentIds: likedCommentIds ?? this.likedCommentIds,
      likeCounts: likeCounts ?? this.likeCounts,
    );
  }

  bool isLiked(String commentId) => likedCommentIds.contains(commentId);
  int getLikeCount(String commentId) => likeCounts[commentId] ?? 0;
}

class CommentLikesNotifier extends StateNotifier<CommentLikesState> {
  final ISocialRepository _repository;

  CommentLikesNotifier(this._repository) : super(const CommentLikesState());

  void initializeFromComments(List<dynamic> comments) {
    final likedIds = <String>{};
    final counts = <String, int>{};

    void processComment(dynamic comment) {
      if (comment.isLiked == true) {
        likedIds.add(comment.id);
      }
      counts[comment.id] = comment.likesCount ?? 0;

      if (comment.replies != null) {
        for (final reply in comment.replies) {
          processComment(reply);
        }
      }
    }

    for (final comment in comments) {
      processComment(comment);
    }

    state = state.copyWith(
      likedCommentIds: likedIds,
      likeCounts: counts,
    );
  }

  void initializeSingleComment(String commentId, bool isLiked, int likeCount) {
    final newLikedIds = Set<String>.from(state.likedCommentIds);
    final newCounts = Map<String, int>.from(state.likeCounts);

    if (isLiked) {
      newLikedIds.add(commentId);
    } else {
      newLikedIds.remove(commentId);
    }
    newCounts[commentId] = likeCount;

    state = state.copyWith(
      likedCommentIds: newLikedIds,
      likeCounts: newCounts,
    );
  }

  Future<bool> toggleLike(String commentId) async {
    final wasLiked = state.isLiked(commentId);
    final previousCount = state.getLikeCount(commentId);

    final newLikedIds = Set<String>.from(state.likedCommentIds);
    final newCounts = Map<String, int>.from(state.likeCounts);

    if (wasLiked) {
      newLikedIds.remove(commentId);
      newCounts[commentId] = previousCount - 1;
    } else {
      newLikedIds.add(commentId);
      newCounts[commentId] = previousCount + 1;
    }

    state = state.copyWith(
      likedCommentIds: newLikedIds,
      likeCounts: newCounts,
    );

    try {
      if (wasLiked) {
        final result = await _repository.unlikeComment(commentId);
        if (result.isLeft()) {
          state = state.copyWith(
            likedCommentIds: wasLiked
                ? {...state.likedCommentIds, commentId}
                : state.likedCommentIds.difference({commentId}),
            likeCounts: {...state.likeCounts, commentId: previousCount},
          );
          return false;
        }
      } else {
        final result = await _repository.likeComment(commentId);
        if (result.isLeft()) {
          state = state.copyWith(
            likedCommentIds: wasLiked
                ? {...state.likedCommentIds, commentId}
                : state.likedCommentIds.difference({commentId}),
            likeCounts: {...state.likeCounts, commentId: previousCount},
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        likedCommentIds: wasLiked
            ? {...state.likedCommentIds, commentId}
            : state.likedCommentIds.difference({commentId}),
        likeCounts: {...state.likeCounts, commentId: previousCount},
      );
      return false;
    }
  }

  bool isLiked(String commentId) => state.isLiked(commentId);
  int getLikeCount(String commentId) => state.getLikeCount(commentId);
}

final commentLikesProvider =
    StateNotifierProvider<CommentLikesNotifier, CommentLikesState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return CommentLikesNotifier(repository);
});
