import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';

part 'feed_provider.g.dart';

final userStoriesProvider = FutureProvider.family<List<StoryEntity>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getUserStories(userId);
  return result.fold((failure) => throw failure, (stories) => stories);
});

void invalidateStoryConsumers(WidgetRef ref, String userId) {
  ref.invalidate(storiesProvider);
  ref.invalidate(userStoriesProvider(userId));
}

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

// Class named FeedTypeSetting (not FeedType) because the FeedType enum lives in
// this library; the generated provider keeps its old name via @Riverpod(name:).
@Riverpod(keepAlive: true, name: 'feedTypeProvider')
class FeedTypeSetting extends _$FeedTypeSetting {
  @override
  FeedType build() => FeedType.explore;

  void set(FeedType value) => state = value;
}

@Riverpod(keepAlive: true, name: 'feedContentFilterProvider')
class FeedContentFilterSetting extends _$FeedContentFilterSetting {
  @override
  FeedContentFilter build() => FeedContentFilter.all;

  void set(FeedContentFilter value) => state = value;
}

@Riverpod(keepAlive: true)
class Feed extends _$Feed {
  SocialRepository get _repository => ref.read(socialRepositoryProvider);
  int _currentRequestId = 0;
  String _scope = 'explore:all';

  @override
  FeedState build() {
    return const FeedState();
  }

  Future<void> loadFeed({
    bool refresh = false,
    String feedType = 'explore',
    String contentFilter = 'all',
  }) async {
    final scope = '$feedType:$contentFilter';
    if (scope != _scope) {
      _scope = scope;
      state = const FeedState();
    }
    if (state.isLoading && !refresh) return;
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

    final requestId = ++_currentRequestId;

    final result = await _repository.getFeed(
      cursor: cursor,
      offset: offset,
      type: feedType,
      contentFilter: contentFilter,
    );

    if (requestId != _currentRequestId || scope != _scope) return;

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (page) => state = state.copyWith(
        posts: refresh
            ? {for (final post in page.posts) post.id: post}.values.toList()
            : {
                for (final post in [...state.posts, ...page.posts])
                  post.id: post,
              }.values.toList(),
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.nextCursor ?? state.cursor,
        offset: page.nextOffset ?? state.offset,
      ),
    );
  }

  void resetFollowing() {
    if (_scope.startsWith('following:')) {
      _currentRequestId++;
      state = const FeedState();
    }
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

final storiesProvider = FutureProvider<StoriesResponse>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getStories();

  return result.fold((failure) => throw failure, (stories) => stories);
});
