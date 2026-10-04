import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/social_filters.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/pagination/paginated_state.dart';
import 'package:freebay/features/social/social.dart';

export 'package:freebay/features/social/data/entities/social_filters.dart';

part 'post_search_provider.g.dart';

const _postSearchPageSize = 20;

class PostSearchState extends PaginatedState<PostEntity, String> {
  final String query;
  final PostSearchFilter filter;

  const PostSearchState({
    List<PostEntity> posts = const [],
    super.isLoading,
    super.hasMore,
    super.cursor,
    super.error,
    this.query = '',
    this.filter = PostSearchFilter.all,
  }) : super(items: posts);

  List<PostEntity> get posts => items;

  PostSearchState copyWith({
    List<PostEntity>? posts,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
    String? error,
    String? query,
    PostSearchFilter? filter,
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

@Riverpod(keepAlive: true)
class PostSearch extends _$PostSearch {
  final PageRequestGuard _requestGuard = PageRequestGuard();
  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  PostSearchState build() {
    return const PostSearchState();
  }

  Future<void> search({
    String? query,
    PostSearchFilter? filter,
    bool refresh = false,
  }) async {
    if (!refresh && (state.isLoading || !state.hasMore)) return;

    final requestId = _requestGuard.begin();
    final newQuery = query ?? state.query;
    final newFilter = filter ?? state.filter;
    final cursor = refresh ? null : state.cursor;

    state = PostSearchState(
      isLoading: true,
      posts: refresh ? [] : state.posts,
      query: newQuery,
      filter: newFilter,
      cursor: cursor,
    );

    final result = await _repository.searchPosts(
      query: newQuery,
      filter: newFilter,
      cursor: cursor,
    );
    if (!ref.mounted || !_requestGuard.isCurrent(requestId)) return;

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (posts) {
        reconcileSocialPosts(ref, posts);
        state = state.copyWith(
          posts: refresh ? posts : [...state.posts, ...posts],
          isLoading: false,
          hasMore: posts.length >= _postSearchPageSize,
          cursor: posts.isNotEmpty ? posts.last.id : state.cursor,
        );
      },
    );
  }

  void clear() {
    _requestGuard.invalidate();
    state = const PostSearchState();
  }
}
