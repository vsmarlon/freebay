import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

class UserSearchState {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? error;

  const UserSearchState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  UserSearchState copyWith({
    List<UserSearchEntity>? users,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return UserSearchState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final ISocialRepository _repository;

  UserSearchNotifier(this._repository) : super(const UserSearchState());

  Future<void> search({String? query, bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final offset = refresh ? 0 : state.offset;

    state = state.copyWith(
      isLoading: true,
      error: null,
      users: refresh ? [] : state.users,
      offset: refresh ? 0 : state.offset,
    );

    final result = await _repository.searchUsers(query: query, offset: offset);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = state.copyWith(
        users: refresh ? page.users : [...state.users, ...page.users],
        isLoading: false,
        hasMore: page.hasMore,
        offset: page.nextOffset ?? state.offset,
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
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (users) => state = state.copyWith(users: users, isLoading: false),
    );
  }
}

final suggestionsProvider =
    StateNotifierProvider<SuggestionsNotifier, SuggestionsState>((ref) {
      final repository = ref.watch(socialRepositoryProvider);
      return SuggestionsNotifier(repository);
    });
