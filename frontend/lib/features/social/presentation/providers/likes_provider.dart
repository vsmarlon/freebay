import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'likes_provider.g.dart';

@Riverpod(keepAlive: true)
class Likes extends _$Likes {
  late final ISocialRepository _repository;

  @override
  LikesState build() {
    _repository = ref.watch(socialRepositoryProvider);
    return const LikesState();
  }

  Future<bool> toggleLike(
    String postId, {
    required bool initialIsLiked,
    required int initialCount,
  }) async {
    final currentLiked = state.likedOverrides[postId] ?? initialIsLiked;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsLiked = !currentLiked;
    final newCount = newIsLiked ? currentCount + 1 : currentCount - 1;

    state = state.copyWith(
      likedOverrides: {...state.likedOverrides, postId: newIsLiked},
      countOverrides: {...state.countOverrides, postId: newCount},
    );

    try {
      final result = newIsLiked
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);

      if (result.isLeft) {
        state = state.copyWith(
          likedOverrides: {...state.likedOverrides, postId: currentLiked},
          countOverrides: {...state.countOverrides, postId: currentCount},
        );
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        likedOverrides: {...state.likedOverrides, postId: currentLiked},
        countOverrides: {...state.countOverrides, postId: currentCount},
      );
      return false;
    }
  }
}
