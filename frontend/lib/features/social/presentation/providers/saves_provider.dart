import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class SavesState {
  /// Map of post IDs to their saved status override (null means use entity value)
  final Map<String, bool> savedOverrides;

  const SavesState({this.savedOverrides = const {}});

  SavesState copyWith({Map<String, bool>? savedOverrides}) =>
      SavesState(savedOverrides: savedOverrides ?? this.savedOverrides);

  bool? getSavedOverride(String postId) => savedOverrides[postId];
}

class SavesNotifier extends StateNotifier<SavesState> {
  final ISocialRepository _repository;

  SavesNotifier(this._repository) : super(const SavesState());

  /// Toggles saved status. If no override exists, it uses the initial value from the entity.
  Future<bool> toggleSave(String postId, {required bool initialIsSaved}) async {
    final currentSaved = state.savedOverrides[postId] ?? initialIsSaved;
    final newIsSaved = !currentSaved;

    // Apply optimistic update
    state = state.copyWith(savedOverrides: {...state.savedOverrides, postId: newIsSaved});

    final result = currentSaved
        ? await _repository.unsavePost(postId)
        : await _repository.savePost(postId);

    return result.fold(
      (_) {
        // Rollback on failure
        state = state.copyWith(savedOverrides: {...state.savedOverrides, postId: currentSaved});
        return false;
      },
      (_) => true,
    );
  }
}

final savesProvider =
    StateNotifierProvider<SavesNotifier, SavesState>((ref) {
  final repository = ref.read(socialRepositoryProvider);
  return SavesNotifier(repository);
});
