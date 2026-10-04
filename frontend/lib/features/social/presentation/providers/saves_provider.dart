import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/providers/social_override_helpers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'saves_provider.g.dart';

@Riverpod(keepAlive: true)
class Saves extends _$Saves {
  int _sessionId = 0;
  Set<String> _inFlight = <String>{};
  Map<String, int> _versions = <String, int>{};
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  SavesState build() {
    _inFlight = <String>{};
    _versions = <String, int>{};
    return const SavesState();
  }

  void clear() {
    _sessionId++;
    _inFlight.clear();
    _versions.clear();
    state = const SavesState();
  }

  void reconcilePosts(Iterable<PostEntity> posts) {
    final overrides = Map<String, bool>.of(state.savedOverrides);
    for (final post in posts) {
      if (_inFlight.contains(post.id)) continue;
      if (overrides.containsKey(post.id) &&
          overrides[post.id] == post.isSaved) {
        overrides.remove(post.id);
        _versions.remove(post.id);
      }
    }
    state = state.copyWith(savedOverrides: overrides);
  }

  Future<bool> toggleSave(String postId, {required bool initialIsSaved}) async {
    if (!_inFlight.add(postId)) return false;
    final sessionId = _sessionId;
    final version = _versions.update(
      postId,
      (current) => current + 1,
      ifAbsent: () => 1,
    );
    final currentSaved = state.savedOverrides[postId] ?? initialIsSaved;
    final newIsSaved = !currentSaved;

    state = state.copyWith(
      savedOverrides: withOverride(state.savedOverrides, postId, newIsSaved),
    );

    try {
      final result = currentSaved
          ? await _repository.unsavePost(postId)
          : await _repository.savePost(postId);
      if (!ref.mounted ||
          sessionId != _sessionId ||
          _versions[postId] != version) {
        return false;
      }

      return result.fold(
        (_) {
          state = state.copyWith(
            savedOverrides: withOverride(
              state.savedOverrides,
              postId,
              currentSaved,
            ),
          );
          return false;
        },
        (authoritative) {
          final overrides = withOverride(
            state.savedOverrides,
            postId,
            authoritative.active,
          );
          if (authoritative.active == initialIsSaved) overrides.remove(postId);
          state = state.copyWith(savedOverrides: overrides);
          return true;
        },
      );
    } catch (_) {
      if (ref.mounted &&
          sessionId == _sessionId &&
          _versions[postId] == version) {
        state = state.copyWith(
          savedOverrides: withOverride(
            state.savedOverrides,
            postId,
            currentSaved,
          ),
        );
      }
      return false;
    } finally {
      if (sessionId == _sessionId) {
        _inFlight.remove(postId);
        _versions.remove(postId);
      }
    }
  }
}
