import 'dart:async';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/social_filters.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/features/social/social.dart';
import 'package:freebay/shared/pagination/paginated_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:freebay/features/social/presentation/providers/social_provider_states.dart';
export 'package:freebay/features/social/data/entities/social_filters.dart';

part 'feed_provider.g.dart';

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
  final PageRequestGuard _requestGuard = PageRequestGuard();
  bool _isLoadingMore = false;
  String _scope = 'explore:all';
  String? _accountId;
  final Set<String> _restoredCacheKeys = {};

  @override
  FeedState build() {
    return const FeedState();
  }

  Future<void> loadFeed({
    bool refresh = false,
    FeedType feedType = FeedType.explore,
    FeedContentFilter contentFilter = FeedContentFilter.all,
  }) async {
    final authState = ref.read(authControllerProvider);
    final accountId = authState.asData?.value?.id;
    if (_accountId != accountId) {
      _isLoadingMore = false;
      _accountId = accountId;
      _restoredCacheKeys.clear();
      _requestGuard.invalidate();
      state = const FeedState();
    }
    final scope = '${feedType.wireValue}:${contentFilter.apiValue}';
    if (scope != _scope) {
      _isLoadingMore = false;
      _scope = scope;
      state = const FeedState();
    }
    if ((state.isLoading || state.isRefreshing) && !refresh) return;
    if (_isLoadingMore && !refresh) return;
    if (!refresh && !state.hasMore) return;

    final cursor = refresh ? null : state.cursor;
    final replacePage = refresh || cursor == null;
    final requestId = _requestGuard.begin();
    _isLoadingMore = !replacePage;

    final canCache =
        accountId != null &&
        feedType == FeedType.explore &&
        contentFilter == FeedContentFilter.all;
    final cacheKey = 'social.explore.public.first-page.v1';
    if (canCache && cursor == null && !_restoredCacheKeys.contains(cacheKey)) {
      _restoredCacheKeys.add(cacheKey);
      final cached = await StorageService.readCachedJson(
        userId: accountId,
        key: cacheKey,
      );
      if (!ref.mounted ||
          !_requestGuard.isCurrent(requestId) ||
          scope != _scope ||
          accountId != ref.read(authControllerProvider).asData?.value?.id) {
        _isLoadingMore = false;
        return;
      }
      final rawPosts = cached?['posts'];
      if (rawPosts is List &&
          rawPosts.every((item) => item is Map<String, dynamic>) &&
          cached?['pageVersion'] == 1 &&
          cached?['limit'] == 20) {
        try {
          final posts = rawPosts
              .whereType<Map<String, dynamic>>()
              .map(PostEntity.fromJson)
              .where((post) => post.audience == PostAudience.everyone)
              .toList();
          if (posts.isNotEmpty) {
            state = state.copyWith(
              posts: posts,
              isLoading: false,
              isStale: true,
            );
          }
        } catch (_) {}
      }
    }

    state = state.copyWith(
      isLoading: state.posts.isEmpty,
      isRefreshing: replacePage && state.posts.isNotEmpty,
      error: null,
      posts: state.posts,
      cursor: state.cursor,
    );

    final result = await _repository.getFeed(
      cursor: cursor,
      type: feedType,
      contentFilter: contentFilter,
    );

    if (!ref.mounted ||
        !_requestGuard.isCurrent(requestId) ||
        scope != _scope) {
      return;
    }
    if (accountId != ref.read(authControllerProvider).asData?.value?.id) {
      _isLoadingMore = false;
      return;
    }

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: failure.message,
      ),
      (page) {
        reconcileSocialPosts(ref, page.posts);
        if (canCache && cursor == null && replacePage) {
          final publicPosts = page.posts
              .where((post) => post.audience == PostAudience.everyone)
              .where((post) => !_hasPrivateMediaUrl(post.imageUrl))
              .toList();
          unawaited(
            StorageService.writeCachedJson(
              userId: accountId,
              key: cacheKey,
              json: {
                'pageVersion': 1,
                'limit': 20,
                'posts': publicPosts.map(_publicPostJson).toList(),
              },
            ),
          );
        }
        state = state.copyWith(
          posts: replacePage
              ? {for (final post in page.posts) post.id: post}.values.toList()
              : {
                  for (final post in [...state.posts, ...page.posts])
                    post.id: post,
                }.values.toList(),
          isLoading: false,
          isRefreshing: false,
          isStale: false,
          hasMore: page.hasMore,
          cursor: page.nextCursor,
        );
      },
    );
    _isLoadingMore = false;
  }

  bool _hasPrivateMediaUrl(String? url) {
    final normalized = url?.toLowerCase();
    return normalized != null &&
        (normalized.contains('/private/') ||
            normalized.contains('/signed/') ||
            normalized.contains('signature=') ||
            normalized.contains('token='));
  }

  Map<String, dynamic> _publicPostJson(PostEntity post) {
    final json = post.toJson();
    json['user'] = _publicUserJson(post.user);
    if (post.repostedBy != null) {
      json['repostedBy'] = _publicUserJson(post.repostedBy!);
    }
    return json;
  }

  Map<String, Object?> _publicUserJson(UserEntity user) => {
    'id': user.id,
    'displayName': user.displayName,
    'username': user.username,
    'avatarUrl': _hasPrivateMediaUrl(user.avatarUrl) ? null : user.avatarUrl,
    'isVerified': user.isVerified,
    'reputationScore': user.reputationScore,
    'totalReviews': user.totalReviews,
    'salesCount': user.salesCount,
    'followersCount': user.followersCount,
    'followingCount': user.followingCount,
    'postsCount': user.postsCount,
    'productsCount': user.productsCount,
  };

  void resetFollowing() {
    if (_scope.startsWith('following:')) {
      _isLoadingMore = false;
      _requestGuard.invalidate();
      state = const FeedState();
    }
  }

  void clear() {
    _requestGuard.invalidate();
    _isLoadingMore = false;
    _accountId = null;
    _restoredCacheKeys.clear();
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
