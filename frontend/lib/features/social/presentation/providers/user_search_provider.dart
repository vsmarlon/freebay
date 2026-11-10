import 'dart:async';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/pagination/paginated_state.dart';

part 'user_search_provider.g.dart';

class UserSearchState extends PaginatedState<UserSearchEntity, int> {
  const UserSearchState({
    List<UserSearchEntity> users = const [],
    super.isLoading,
    super.hasMore,
    int offset = 0,
    super.error,
  }) : super(items: users, cursor: offset);

  List<UserSearchEntity> get users => items;
  int get offset => cursor ?? 0;

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
  final PageRequestGuard _requestGuard = PageRequestGuard();
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  UserSearchState build() {
    return const UserSearchState();
  }

  Future<void> search({String? query, bool refresh = false}) async {
    if (!refresh && (state.isLoading || !state.hasMore)) return;

    final requestId = _requestGuard.begin();
    final offset = refresh ? 0 : state.offset;

    state = UserSearchState(
      isLoading: true,
      users: refresh ? [] : state.users,
      offset: offset,
    );

    final normalizedQuery = query?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final result = await _repository.searchUsers(
      query: normalizedQuery,
      offset: offset,
    );
    if (!ref.mounted || !_requestGuard.isCurrent(requestId)) return;

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
    _requestGuard.invalidate();
    state = const UserSearchState();
  }
}

class SuggestionsState {
  final List<UserSearchEntity> users;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? error;

  const SuggestionsState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  SuggestionsState copyWith({
    List<UserSearchEntity>? users,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return SuggestionsState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

/// Kept alive for the entire app session — never disposed between tab switches.
/// Only invalidated explicitly after a follow/unfollow action via [ref.invalidate].
@Riverpod(keepAlive: true)
class Suggestions extends _$Suggestions {
  int _sessionId = 0;
  final PageRequestGuard _requestGuard = PageRequestGuard();
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
    _requestGuard.invalidate();
    state = const SuggestionsState();
  }

  Future<void> loadSuggestions() async {
    if (state.isLoading) return;

    final sessionId = _sessionId;
    final requestId = _requestGuard.begin();
    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestionsPage();
    if (!ref.mounted ||
        sessionId != _sessionId ||
        !_requestGuard.isCurrent(requestId)) {
      return;
    }

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = state.copyWith(
        users: page.users,
        hasMore: page.hasMore,
        offset: page.nextOffset ?? 0,
        isLoading: false,
      ),
    );
  }

  /// Force-refresh after the user follows or unfollows someone.
  Future<void> refresh() async {
    final sessionId = _sessionId;
    final requestId = _requestGuard.begin();
    state = const SuggestionsState(isLoading: true);
    final result = await _repository.getSuggestionsPage();
    if (!ref.mounted ||
        sessionId != _sessionId ||
        !_requestGuard.isCurrent(requestId)) {
      return;
    }
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = state.copyWith(
        users: page.users,
        hasMore: page.hasMore,
        offset: page.nextOffset ?? 0,
        isLoading: false,
      ),
    );
  }

  /// Fetches more suggestions and appends them to the current list
  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;
    final sessionId = _sessionId;
    final requestId = _requestGuard.begin();
    state = state.copyWith(isLoading: true);

    final result = await _repository.getSuggestionsPage(offset: state.offset);
    if (!ref.mounted ||
        sessionId != _sessionId ||
        !_requestGuard.isCurrent(requestId)) {
      return;
    }
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) {
        // filter out duplicates
        final currentIds = state.users.map((u) => u.id).toSet();
        final uniqueNew = page.users
            .where((u) => !currentIds.contains(u.id))
            .toList();
        state = state.copyWith(
          users: [...state.users, ...uniqueNew],
          hasMore: page.hasMore,
          offset: page.nextOffset ?? state.offset,
          isLoading: false,
        );
      },
    );
  }
}

@riverpod
Future<List<UserSearchEntity>> quoteMentionCandidates(
  Ref ref,
  String query,
) async {
  final userId = ref.watch(authControllerProvider).value?.id;
  if (userId == null) return const [];
  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (!ref.mounted) return const [];
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    final suggestions = await ref
        .read(socialRepositoryProvider)
        .getSuggestionsPage();
    return suggestions.fold((failure) => throw failure, (page) => page.users);
  }
  final result = await ref
      .read(socialRepositoryProvider)
      .searchUsers(query: trimmed);
  return result.fold((failure) => throw failure, (page) => page.users);
}
