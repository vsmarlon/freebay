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
  late final SocialRepository _repository;

  @override
  UserSearchState build() {
    _repository = ref.watch(socialRepositoryProvider);
    return const UserSearchState();
  }

  Future<void> search({String? query, bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final offset = refresh ? 0 : state.offset;

    state = state.copyWith(
      isLoading: true,
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
  late final SocialRepository _repository;

  @override
  SuggestionsState build() {
    _repository = ref.watch(socialRepositoryProvider);
    // Load once on first creation; subsequent tab switches reuse cached state.
    Future.microtask(loadSuggestions);
    return const SuggestionsState();
  }

  Future<void> loadSuggestions() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestions();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (users) => state = state.copyWith(users: users, isLoading: false),
    );
  }

  /// Force-refresh after the user follows or unfollows someone.
  Future<void> refresh() async {
    state = state.copyWith(users: [], isLoading: true);
    final result = await _repository.getSuggestions();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (users) => state = state.copyWith(users: users, isLoading: false),
    );
  }

  /// Fetches more suggestions and appends them to the current list
  Future<void> fetchMore() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestions();
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
