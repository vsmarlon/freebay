import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_override_helpers.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'likes_provider.g.dart';

@Riverpod(keepAlive: true)
class Likes extends _$Likes {
  int _sessionId = 0;
  Set<String> _inFlight = <String>{};
  Map<String, int> _versions = <String, int>{};
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  LikesState build() {
    _inFlight = <String>{};
    _versions = <String, int>{};
    return const LikesState();
  }

  void clear() {
    _sessionId++;
    _inFlight.clear();
    _versions.clear();
    state = const LikesState();
  }

  bool isPostLiked(String postId, {bool initial = false}) =>
      state.getLikedOverride(postId) ?? initial;

  int postLikesCount(String postId, {int initial = 0}) =>
      state.getCountOverride(postId) ?? initial;

  void reconcilePosts(Iterable<PostEntity> posts) {
    final liked = Map<String, bool>.of(state.likedOverrides);
    final counts = Map<String, int>.of(state.countOverrides);
    for (final post in posts) {
      if (_inFlight.contains(post.id)) continue;
      var reconciled = false;
      if (liked.containsKey(post.id) && liked[post.id] == post.isLiked) {
        liked.remove(post.id);
        reconciled = true;
      }
      if (counts.containsKey(post.id) && counts[post.id] == post.likesCount) {
        counts.remove(post.id);
        reconciled = true;
      }
      if (reconciled) _versions.remove(post.id);
    }
    state = state.copyWith(likedOverrides: liked, countOverrides: counts);
  }

  Future<bool> toggleLike(
    String postId, {
    required bool initialIsLiked,
    required int initialCount,
  }) async {
    if (!_inFlight.add(postId)) return false;
    final sessionId = _sessionId;
    final version = _versions.update(
      postId,
      (current) => current + 1,
      ifAbsent: () => 1,
    );
    final currentLiked = state.likedOverrides[postId] ?? initialIsLiked;
    final currentCount = state.countOverrides[postId] ?? initialCount;
    final newIsLiked = !currentLiked;
    final newCount = newIsLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);
    state = state.copyWith(
      likedOverrides: withOverride(state.likedOverrides, postId, newIsLiked),
      countOverrides: withOverride(state.countOverrides, postId, newCount),
    );

    try {
      final result = newIsLiked
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);
      if (!ref.mounted ||
          sessionId != _sessionId ||
          _versions[postId] != version) {
        return false;
      }
      if (result.isLeft) {
        _restore(postId, currentLiked, currentCount);
        return false;
      }
      return result.fold((_) => false, (authoritative) {
        state = state.copyWith(
          likedOverrides: withOverride(
            state.likedOverrides,
            postId,
            authoritative.active,
          ),
          countOverrides: withOverride(
            state.countOverrides,
            postId,
            authoritative.count,
          ),
        );
        if (authoritative.active == initialIsLiked &&
            authoritative.count == initialCount) {
          final liked = Map<String, bool>.of(state.likedOverrides)
            ..remove(postId);
          final counts = Map<String, int>.of(state.countOverrides)
            ..remove(postId);
          state = state.copyWith(likedOverrides: liked, countOverrides: counts);
        }
        return true;
      });
    } catch (_) {
      if (ref.mounted &&
          sessionId == _sessionId &&
          _versions[postId] == version) {
        _restore(postId, currentLiked, currentCount);
      }
      return false;
    } finally {
      if (sessionId == _sessionId) {
        _inFlight.remove(postId);
        _versions.remove(postId);
      }
    }
  }

  void _restore(String postId, bool liked, int count) {
    state = state.copyWith(
      likedOverrides: withOverride(state.likedOverrides, postId, liked),
      countOverrides: withOverride(state.countOverrides, postId, count),
    );
  }
}
