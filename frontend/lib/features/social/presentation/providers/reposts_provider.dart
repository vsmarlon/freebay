import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_override_helpers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'reposts_provider.g.dart';

@Riverpod(keepAlive: true)
class Reposts extends _$Reposts {
  int _sessionId = 0;
  Set<String> _inFlight = <String>{};
  Map<String, int> _versions = <String, int>{};
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  RepostsState build() {
    _inFlight = <String>{};
    _versions = <String, int>{};
    return const RepostsState();
  }

  void clear() {
    _sessionId++;
    _inFlight.clear();
    _versions.clear();
    state = const RepostsState();
  }

  void reconcilePosts(Iterable<PostEntity> posts) {
    final active = Map<String, bool>.of(state.repostedOverrides);
    final counts = Map<String, int>.of(state.countOverrides);
    for (final post in posts) {
      if (_inFlight.contains(post.id)) continue;
      var reconciled = false;
      if (active.containsKey(post.id) && active[post.id] == post.hasReposted) {
        active.remove(post.id);
        reconciled = true;
      }
      if (counts.containsKey(post.id) && counts[post.id] == post.sharesCount) {
        counts.remove(post.id);
        reconciled = true;
      }
      if (reconciled) _versions.remove(post.id);
    }
    state = state.copyWith(repostedOverrides: active, countOverrides: counts);
  }

  Future<bool> toggleRepost(
    String postId, {
    required bool initialIsReposted,
    required int initialCount,
  }) async {
    if (!_inFlight.add(postId)) return false;
    final sessionId = _sessionId;
    final version = _versions.update(
      postId,
      (current) => current + 1,
      ifAbsent: () => 1,
    );
    final currentReposted =
        state.repostedOverrides[postId] ?? initialIsReposted;
    final currentCount = state.countOverrides[postId] ?? initialCount;

    final newIsReposted = !currentReposted;
    final newCount = newIsReposted
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    state = state.copyWith(
      repostedOverrides: withOverride(
        state.repostedOverrides,
        postId,
        newIsReposted,
      ),
      countOverrides: withOverride(state.countOverrides, postId, newCount),
    );

    try {
      final result = newIsReposted
          ? await _repository.repost(postId)
          : await _repository.unrepost(postId);
      if (!ref.mounted ||
          sessionId != _sessionId ||
          _versions[postId] != version) {
        return false;
      }

      if (result.isLeft) {
        state = state.copyWith(
          repostedOverrides: withOverride(
            state.repostedOverrides,
            postId,
            currentReposted,
          ),
          countOverrides: withOverride(
            state.countOverrides,
            postId,
            currentCount,
          ),
        );
        return false;
      }
      return result.fold((_) => false, (authoritative) {
        final reposted = withOverride(
          state.repostedOverrides,
          postId,
          authoritative.active,
        );
        final counts = withOverride(
          state.countOverrides,
          postId,
          authoritative.count,
        );
        if (authoritative.active == initialIsReposted &&
            authoritative.count == initialCount) {
          reposted.remove(postId);
          counts.remove(postId);
        }
        state = state.copyWith(
          repostedOverrides: reposted,
          countOverrides: counts,
        );
        return true;
      });
    } catch (e) {
      if (!ref.mounted ||
          sessionId != _sessionId ||
          _versions[postId] != version) {
        return false;
      }
      state = state.copyWith(
        repostedOverrides: withOverride(
          state.repostedOverrides,
          postId,
          currentReposted,
        ),
        countOverrides: withOverride(
          state.countOverrides,
          postId,
          currentCount,
        ),
      );
      return false;
    } finally {
      if (sessionId == _sessionId) {
        _inFlight.remove(postId);
        _versions.remove(postId);
      }
    }
  }
}
