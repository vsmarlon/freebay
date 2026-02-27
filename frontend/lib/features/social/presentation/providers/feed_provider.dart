import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'package:freebay/features/social/domain/repositories/i_social_repository.dart';

final socialRepositoryProvider = Provider<ISocialRepository>((ref) {
  return SocialRepository();
});

class FeedState {
  final List<PostEntity> posts;
  final bool isLoading;
  final bool hasMore;
  final String? cursor;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  FeedState copyWith({
    List<PostEntity>? posts,
    bool? isLoading,
    bool? hasMore,
    String? cursor,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ISocialRepository _repository;

  FeedNotifier(this._repository) : super(const FeedState());

  Future<void> loadFeed({bool refresh = false}) async {
    if (state.isLoading) return;

    final cursor = refresh ? null : state.cursor;

    state = state.copyWith(
      isLoading: true,
      error: null,
      posts: refresh ? [] : state.posts,
    );

    final result = await _repository.getFeed(cursor: cursor);

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

  Future<void> refresh() async {
    await loadFeed(refresh: true);
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
