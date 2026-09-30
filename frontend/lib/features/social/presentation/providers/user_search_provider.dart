import 'dart:async';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_search_provider.g.dart';

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

@Riverpod(keepAlive: true)
class UserSearch extends _$UserSearch {
  int _requestId = 0;
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  UserSearchState build() {
    return const UserSearchState();
  }

  Future<void> search({String? query, bool refresh = false}) async {
    if (!refresh && (state.isLoading || !state.hasMore)) return;

    final requestId = ++_requestId;
    final offset = refresh ? 0 : state.offset;

    state = UserSearchState(
      isLoading: true,
      users: refresh ? [] : state.users,
      offset: offset,
    );

    final result = await _repository.searchUsers(query: query, offset: offset);
    if (!ref.mounted || requestId != _requestId) return;

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
    _requestId++;
    state = const UserSearchState();
  }
}

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

/// Kept alive for the entire app session — never disposed between tab switches.
/// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].
@Riverpod(keepAlive: true)
class Suggestions extends _$Suggestions {
  int _sessionId = 0;
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  SuggestionsState build() {
    // Load once on first creation; subsequent tab switches reuse cached state.
    final sessionId = _sessionId;
    Future.microtask(() {
      if (ref.mounted && sessionId == _sessionId) loadSuggestions();
    });
    return const SuggestionsState();
  }

  void clear() {
    _sessionId++;
    state = const SuggestionsState();
  }

  Future<void> loadSuggestions() async {
    if (state.isLoading) return;

    final sessionId = _sessionId;
    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestions();
    if (!ref.mounted || sessionId != _sessionId) return;

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (users) => state = state.copyWith(users: users, isLoading: false),
    );
  }

  /// Force-refresh after the user follows or unfollows someone.
  Future<void> refresh() async {
    final sessionId = _sessionId;
    state = state.copyWith(users: [], isLoading: true);
    final result = await _repository.getSuggestions();
    if (!ref.mounted || sessionId != _sessionId) return;
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (users) => state = state.copyWith(users: users, isLoading: false),
    );
  }

  /// Fetches more suggestions and appends them to the current list
  Future<void> fetchMore() async {
    if (state.isLoading) return;
    final sessionId = _sessionId;
    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestions();
    if (!ref.mounted || sessionId != _sessionId) return;
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (newUsers) {
        // filter out duplicates
        final currentIds = state.users.map((u) => u.id).toSet();
        final uniqueNew = newUsers
            .where((u) => !currentIds.contains(u.id))
            .toList();
        state = state.copyWith(
          users: [...state.users, ...uniqueNew],
          isLoading: false,
        );
      },
    );
  }
}
