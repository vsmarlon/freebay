import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'comment_likes_provider.g.dart';

@Riverpod(keepAlive: true)
class CommentLikes extends _$CommentLikes {
  late final SocialRepository _repository;

  @override
  CommentLikesState build() {
    _repository = ref.watch(socialRepositoryProvider);
    return const CommentLikesState();
  }

  Future<bool> toggleLike(
    String commentId, {
    required bool initialIsLiked,
    required int initialCount,
  }) async {
    final currentLiked = state.likedOverrides[commentId] ?? initialIsLiked;
    final currentCount = state.countOverrides[commentId] ?? initialCount;

    final newIsLiked = !currentLiked;
    final newCount = newIsLiked ? currentCount + 1 : currentCount - 1;

    state = state.copyWith(
      likedOverrides: {...state.likedOverrides, commentId: newIsLiked},
      countOverrides: {...state.countOverrides, commentId: newCount},
    );

    try {
      final result = newIsLiked
          ? await _repository.likeComment(commentId)
          : await _repository.unlikeComment(commentId);

      if (result.isLeft) {
        state = state.copyWith(
          likedOverrides: {...state.likedOverrides, commentId: currentLiked},
          countOverrides: {...state.countOverrides, commentId: currentCount},
        );
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        likedOverrides: {...state.likedOverrides, commentId: currentLiked},
        countOverrides: {...state.countOverrides, commentId: currentCount},
      );
      return false;
    }
  }
}
