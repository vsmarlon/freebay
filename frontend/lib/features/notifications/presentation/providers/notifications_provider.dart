import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/data/repositories/notification_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_provider.g.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  AsyncValue<List<NotificationEntity>> build() {
    ref.watch(notificationRepositoryProvider);
    Future.microtask(loadNotifications);
    return const AsyncValue.loading();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .getNotifications();
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      state = AsyncValue.data(page.items);
    } catch (e, st) {
      ErrorReporter.report('notifications', e, st);
      state = AsyncValue.error(const UnknownFailure(), st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    _isLoadingMore = true;
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(cursor: _nextCursor);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      state = AsyncValue.data([...(state.value ?? const []), ...page.items]);
    } catch (_) {
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    state.whenData((list) {
      state = AsyncValue.data(
        list
            .map((n) => n.id == notificationId ? n.copyWith(read: true) : n)
            .toList(),
      );
    });
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state.whenData((list) {
      state = AsyncValue.data(list.map((n) => n.copyWith(read: true)).toList());
    });
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
    } catch (_) {}
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}

@Riverpod(keepAlive: true)
class UnreadCount extends _$UnreadCount {
  @override
  int build() {
    ref.watch(notificationRepositoryProvider);
    // Preserve the eager load that used to happen in the constructor.
    Future.microtask(loadUnreadCount);
    return 0;
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await ref
          .read(notificationRepositoryProvider)
          .getUnreadCount();
      state = count;
    } catch (e) {
      state = 0;
    }
  }

  void increment() {
    state = state + 1;
  }
}
