import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/features/social/data/entities/user_post_entry.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';

part 'profile_timeline_provider.g.dart';

class ProfileTimelineState {
  const ProfileTimelineState({
    this.entries = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  final List<UserPostEntry> entries;
  final String? cursor;
  final bool hasMore;
  final bool isLoading;
  final String? error;
}

@riverpod
class ProfileTimeline extends _$ProfileTimeline {
  @override
  ProfileTimelineState build(String userId) {
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
    final result = await ref
        .read(socialRepositoryProvider)
        .getProfileTimeline(userId, cursor: state.cursor);
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = ProfileTimelineState(
        entries: state.entries,
        cursor: state.cursor,
        hasMore: state.hasMore,
        error: failure.message,
      ),
      (page) => state = ProfileTimelineState(
        entries: [...state.entries, ...page.items],
        cursor: page.nextCursor,
        hasMore: page.hasMore,
      ),
    );
  }
}
