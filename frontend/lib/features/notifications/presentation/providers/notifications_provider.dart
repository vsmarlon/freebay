import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/notifications/data/models/notification_model.dart';
import 'package:freebay/features/notifications/data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ref.read(notificationRepositoryProvider));
});

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  return UnreadCountNotifier(ref.read(notificationRepositoryProvider));
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;

  NotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await loadNotifications();
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationRepository _repository;

  UnreadCountNotifier(this._repository) : super(0) {
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = count;
    } catch (e) {
      state = 0;
    }
  }

  void increment() {
    state = state + 1;
  }
}
