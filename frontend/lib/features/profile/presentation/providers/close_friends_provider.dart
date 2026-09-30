import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class CloseFriendsNotifier
    extends StateNotifier<AsyncValue<List<CloseFriendCandidate>>> {
  CloseFriendsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadMore();
  }

  final Ref _ref;
  String _search = '';
  bool _selected = false;
  bool hasMore = true;
  bool _loading = false;
  int _requestId = 0;

  Future<Failure?> loadMore({
    bool refresh = false,
    String? search,
    bool? selected,
  }) async {
    if (refresh) {
      _search = search ?? _search;
      _selected = selected ?? _selected;
      hasMore = true;
      _requestId++;
      _loading = false;
    }
    if (_loading || !hasMore) return null;
    final requestId = ++_requestId;
    final previous = refresh
        ? const <CloseFriendCandidate>[]
        : state.value ?? const <CloseFriendCandidate>[];
    _loading = true;
    if (previous.isEmpty) state = const AsyncValue.loading();
    final result = await _ref
        .read(profileRepositoryProvider)
        .getCloseFriendCandidates(
          search: _search,
          selected: _selected,
          offset: previous.length,
        );
    if (!mounted || requestId != _requestId) return null;
    _loading = false;
    return result.fold(
      (failure) {
        if (previous.isEmpty) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
        return failure;
      },
      (page) {
        hasMore = page.length == 20;
        state = AsyncValue.data([...previous, ...page]);
        return null;
      },
    );
  }
}

final closeFriendsProvider =
    StateNotifierProvider.autoDispose<
      CloseFriendsNotifier,
      AsyncValue<List<CloseFriendCandidate>>
    >((ref) {
      ref.watch(authControllerProvider.select((state) => state.value?.id));
      return CloseFriendsNotifier(ref);
    });
