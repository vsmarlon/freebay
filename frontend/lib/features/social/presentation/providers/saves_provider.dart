import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'saves_provider.g.dart';

@Riverpod(keepAlive: true)
class Saves extends _$Saves {
  int _sessionId = 0;
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  SavesState build() {
    return const SavesState();
  }

  void clear() {
    _sessionId++;
    state = const SavesState();
  }

  Future<bool> toggleSave(String postId, {required bool initialIsSaved}) async {
    final sessionId = _sessionId;
    final currentSaved = state.savedOverrides[postId] ?? initialIsSaved;
    final newIsSaved = !currentSaved;

    state = state.copyWith(
      savedOverrides: {...state.savedOverrides, postId: newIsSaved},
    );

    final result = currentSaved
        ? await _repository.unsavePost(postId)
        : await _repository.savePost(postId);
    if (!ref.mounted || sessionId != _sessionId) return false;

    return result.fold(
      (_) {
        state = state.copyWith(
          savedOverrides: {...state.savedOverrides, postId: currentSaved},
        );
        return false;
      },
      (authoritative) {
        state = state.copyWith(
          savedOverrides: {
            ...state.savedOverrides,
            postId: authoritative.active,
          },
        );
        return true;
      },
    );
  }
}
