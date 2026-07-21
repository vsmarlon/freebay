import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

enum FeedType { explore, following }

enum FeedContentFilter { all, socialOnly, sellingOnly }

extension FeedContentFilterApi on FeedContentFilter {
  String get apiValue {
    switch (this) {
      case FeedContentFilter.socialOnly:
        return 'social';
      case FeedContentFilter.sellingOnly:
        return 'selling';
      case FeedContentFilter.all:
        return 'all';
    }
  }
}

final feedTypeProvider = StateProvider<FeedType>((ref) => FeedType.explore);

final feedContentFilterProvider = StateProvider<FeedContentFilter>(
  (ref) => FeedContentFilter.all,
);

class FeedState {
  final List<PostEntity> posts;
  final bool isLoading;
  final bool hasMore;
  final String? cursor;
  final int offset;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
    this.offset = 0,
    this.error,
  });

  FeedState copyWith({
    List<PostEntity>? posts,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
    int? offset,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ISocialRepository _repository;

  FeedNotifier(this._repository) : super(const FeedState());

  Future<void> loadFeed({
    bool refresh = false,
    String feedType = 'explore',
    String contentFilter = 'all',
  }) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final isFollowing = feedType == 'following';
    final cursor = refresh ? null : (isFollowing ? state.cursor : null);
    final offset = refresh ? 0 : (isFollowing ? 0 : state.offset);

    state = state.copyWith(
      isLoading: true,
      error: null,
      posts: refresh ? [] : state.posts,
      cursor: refresh ? null : state.cursor,
      offset: refresh ? 0 : state.offset,
    );

    final result = await _repository.getFeed(
      cursor: cursor,
      offset: offset,
      type: feedType,
      contentFilter: contentFilter,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = state.copyWith(
        posts: refresh ? page.posts : [...state.posts, ...page.posts],
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.nextCursor ?? state.cursor,
        offset: page.nextOffset ?? state.offset,
      ),
    );
  }

  Future<void> refresh({
    String feedType = 'explore',
    String contentFilter = 'all',
  }) async {
    await loadFeed(
      refresh: true,
      feedType: feedType,
      contentFilter: contentFilter,
    );
  }

  void updatePostLike(String postId, bool isLiked, int newCount) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(isLiked: isLiked, likesCount: newCount);
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  void updateSharesCount(String postId, int newCount) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(sharesCount: newCount);
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  void updatePostCommentCount(String postId, int delta) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(commentsCount: post.commentsCount + delta);
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  void addPost(PostEntity post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return FeedNotifier(repository);
});

final storiesProvider = FutureProvider<StoriesResponse>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getStories();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (stories) => stories,
  );
});
