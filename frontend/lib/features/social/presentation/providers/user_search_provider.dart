import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';

final socialRepositoryProvider = Provider<ISocialRepository>((ref) {
  return SocialRepository();
});

class UserSearchState {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final bool hasMore;
  final String? cursor;
  final String? error;

  const UserSearchState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  UserSearchState copyWith({
    List<UserSearchEntity>? users,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
    String? error,
  }) {
    return UserSearchState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error,
    );
  }
}

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final ISocialRepository _repository;

  UserSearchNotifier(this._repository) : super(const UserSearchState());

  Future<void> search({String? query, bool refresh = false}) async {
    if (state.isLoading) return;

    final cursor = refresh ? null : state.cursor;

    state = state.copyWith(
      isLoading: true,
      error: null,
      users: refresh ? [] : state.users,
    );

    final result = await _repository.searchUsers(
      query: query,
      cursor: cursor,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (users) => state = state.copyWith(
        users: refresh ? users : [...state.users, ...users],
        isLoading: false,
        hasMore: users.length >= 20,
        cursor: users.isNotEmpty ? users.last.id : state.cursor,
      ),
    );
  }

  void clear() {
    state = const UserSearchState();
  }
}

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return UserSearchNotifier(repository);
});

class SuggestionsState {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final String? error;

  const SuggestionsState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  SuggestionsState copyWith({
    List<UserSearchEntity>? users,
    bool? isLoading,
    String? error,
  }) {
    return SuggestionsState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SuggestionsNotifier extends StateNotifier<SuggestionsState> {
  final ISocialRepository _repository;

  SuggestionsNotifier(this._repository) : super(const SuggestionsState());

  Future<void> loadSuggestions() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSuggestions();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (users) => state = state.copyWith(
        users: users,
        isLoading: false,
      ),
    );
  }
}

final suggestionsProvider =
    StateNotifierProvider<SuggestionsNotifier, SuggestionsState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return SuggestionsNotifier(repository);
});
