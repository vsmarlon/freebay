import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/shared/pagination/paginated_state.dart';
import 'package:freebay/features/social/social.dart';

part 'profile_timeline_provider.g.dart';

class ProfileTimelineState extends PaginatedState<UserPostEntry, String> {
  const ProfileTimelineState({
    List<UserPostEntry> entries = const [],
    super.cursor,
    super.hasMore,
    super.isLoading,
    super.error,
  }) : super(items: entries);

  List<UserPostEntry> get entries => items;
}

@riverpod
class ProfileTimeline extends _$ProfileTimeline {
  final PageRequestGuard _requestGuard = PageRequestGuard();
  final Set<CancelToken> _cancelTokens = {};

  @override
  ProfileTimelineState build(String userId, {String? kind, String? viewerId}) {
    ref.onDispose(() {
      _requestGuard.invalidate();
      for (final token in _cancelTokens) {
        token.cancel();
      }
      _cancelTokens.clear();
    });
    Future.microtask(loadMore);
    return const ProfileTimelineState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = ProfileTimelineState(
      entries: state.entries,
      cursor: state.cursor,
      hasMore: state.hasMore,
      isLoading: true,
    );
    final requestId = _requestGuard.begin();
    final cancelToken = CancelToken();
    _cancelTokens.add(cancelToken);
    final result = await ref
        .read(socialRepositoryProvider)
        .getProfileTimeline(
          userId,
          cursor: state.cursor,
          kind: kind,
          cancelToken: cancelToken,
        );
    _cancelTokens.remove(cancelToken);
    if (!ref.mounted || !_requestGuard.isCurrent(requestId)) return;
    result.fold(
      (failure) => state = ProfileTimelineState(
        entries: state.entries,
        cursor: state.cursor,
        hasMore: state.hasMore,
        error: failure.message,
      ),
      (page) {
        reconcileSocialPosts(
          ref,
          page.items.map((entry) => entry.toPostEntity()),
        );
        state = ProfileTimelineState(
          entries: {
            for (final entry in [...state.entries, ...page.items])
              entry.repostId ?? entry.post.id: entry,
          }.values.toList(),
          cursor: page.nextCursor,
          hasMore: page.hasMore && page.nextCursor != null,
        );
      },
    );
  }
}
