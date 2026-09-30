import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/data/entities/social_filters.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
export 'package:freebay/features/social/data/entities/social_filters.dart';

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
    FeedType feedType = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) async {
    final scope = '${feedType.wireValue}:${contentFilter.apiValue}';
    if (scope != _scope) {
      _scope = scope;
      state = const FeedState();
    }
    if (state.isLoading && !refresh) return;
    if (!refresh && !state.hasMore) return;

    final cursor = refresh ? null : state.cursor;

    state = state.copyWith(
      isLoading: true,
      error: null,
      posts: refresh ? [] : state.posts,
      cursor: refresh ? null : state.cursor,
    );

    final requestId = ++_currentRequestId;

    final result = await _repository.getFeed(
      cursor: cursor,
      type: feedType,
      contentFilter: contentFilter,
    );

    if (!ref.mounted || requestId != _currentRequestId || scope != _scope) {
      return;
    }

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
        cursor: page.nextCursor,
      ),
    );
  }

  void resetFollowing() {
    if (_scope.startsWith('following:')) {
      _currentRequestId++;
      state = const FeedState();
    }
  }

  void clear() {
    _currentRequestId++;
    _scope = 'explore:all';
    state = const FeedState();
  }

  Future<void> refresh({
    FeedType feedType = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
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

  void removePost(String id) {
    state = state.copyWith(
      posts: state.posts.where((post) => post.id != id).toList(),
    );
  }
}

final storiesProvider = FutureProvider<StoriesResponse>((ref) async {
  final repository = ref.watch(socialRepositoryProvider);
  final result = await repository.getStories();

  return result.fold((failure) => throw failure, (stories) => stories);
});
