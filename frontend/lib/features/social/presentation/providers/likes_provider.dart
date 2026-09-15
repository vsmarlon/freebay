import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'likes_provider.g.dart';

@Riverpod(keepAlive: true)
class Likes extends _$Likes {
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  LikesState build() {
    return const LikesState();
  }

  bool isPostLiked(String postId, {bool initial = false}) =>
      state.getLikedOverride(postId) ?? initial;

  int postLikesCount(String postId, {int initial = 0}) =>
      state.getCountOverride(postId) ?? initial;

  Future<bool> toggleLike(
    String postId, {
    required bool initialIsLiked,
    required int initialCount,
  }) async {
    final currentLiked = state.likedOverrides[postId] ?? initialIsLiked;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsLiked = !currentLiked;
    final newCount = newIsLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    state = state.copyWith(
      likedOverrides: {...state.likedOverrides, postId: newIsLiked},
      countOverrides: {...state.countOverrides, postId: newCount},
    );
    ref
        .read(feedProvider.notifier)
        .updatePostLike(postId, newIsLiked, newCount);

    try {
      final result = newIsLiked
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);

      if (result.isLeft) {
        state = state.copyWith(
          likedOverrides: {...state.likedOverrides, postId: currentLiked},
          countOverrides: {...state.countOverrides, postId: currentCount},
        );
        ref
            .read(feedProvider.notifier)
            .updatePostLike(postId, currentLiked, currentCount);
        return false;
      }
      return result.fold((_) => false, (authoritative) {
        state = state.copyWith(
          likedOverrides: {
            ...state.likedOverrides,
            postId: authoritative.active,
          },
          countOverrides: {
            ...state.countOverrides,
            postId: authoritative.count,
          },
        );
        ref
            .read(feedProvider.notifier)
            .updatePostLike(postId, authoritative.active, authoritative.count);
        return true;
      });
    } catch (e) {
      state = state.copyWith(
        likedOverrides: {...state.likedOverrides, postId: currentLiked},
        countOverrides: {...state.countOverrides, postId: currentCount},
      );
      ref
          .read(feedProvider.notifier)
          .updatePostLike(postId, currentLiked, currentCount);
      return false;
    }
  }
}
