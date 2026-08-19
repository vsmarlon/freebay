import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/data/repositories/notification_repository.dart';
import 'package:freebay/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_provider.g.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  @override
  AsyncValue<List<NotificationEntity>> build() {
    ref.watch(notificationRepositoryProvider);
    // Preserve the eager load that used to happen in the constructor.
    Future.microtask(loadNotifications);
    return const AsyncValue.loading();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await ref
          .read(notificationRepositoryProvider)
          .getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
