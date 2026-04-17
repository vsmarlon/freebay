import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'user_search_provider.dart';

class PostSearchState {
  final List<PostEntity> posts;
  final bool isLoading;
  final bool hasMore;
  final String? cursor;
  final String? error;
  final String query;
  final String filter;

  const PostSearchState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
    this.error,
    this.query = '',
    this.filter = 'all',
  });

  PostSearchState copyWith({
    List<PostEntity>? posts,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
    String? error,
    String? query,
    String? filter,
  }) {
    return PostSearchState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class PostSearchNotifier extends StateNotifier<PostSearchState> {
  final ISocialRepository _repository;

  PostSearchNotifier(this._repository) : super(const PostSearchState());

  Future<void> search(
      {String? query, String? filter, bool refresh = false}) async {
    if (state.isLoading) return;

    final newQuery = query ?? state.query;
    final newFilter = filter ?? state.filter;
    final cursor = refresh ? null : state.cursor;

    state = state.copyWith(
      isLoading: true,
      error: null,
      posts: refresh ? [] : state.posts,
      query: newQuery,
      filter: newFilter,
    );

    final result = await _repository.searchPosts(
      query: newQuery,
      filter: newFilter,
      cursor: cursor,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (posts) => state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= 20,
        cursor: posts.isNotEmpty ? posts.last.id : state.cursor,
      ),
    );
  }

  void clear() {
    state = const PostSearchState();
  }
}

final postSearchProvider =
    StateNotifierProvider<PostSearchNotifier, PostSearchState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return PostSearchNotifier(repository);
});
