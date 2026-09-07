import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';

class NotificationRepository extends BaseHttpRepository {
  NotificationRepository({super.client});

  Future<CursorPage<NotificationEntity>> getNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    final result = await safePage<NotificationEntity>(
      '/notifications',
      NotificationEntity.fromJson,
      cursor: cursor,
      limit: limit,
    );
    return result.rightOrNull ?? const CursorPage<NotificationEntity>.empty();
  }

  Future<int> getUnreadCount() async {
    final result = await safeGet<int>(
      '/notifications/unread-count',
      extractKey: 'data.count',
      customMapper: (d) => (d as int?) ?? 0,
    );
    return result.rightOrNull ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await safeVoid(() => client.patch('/notifications/$notificationId/read'));
  }

  Future<void> markAllAsRead() async {
    await safeVoid(() => client.post('/notifications/read-all'));
  }

  Future<void> updateFcmToken(String token) async {
    await safeVoid(
      () => client.patch('/users/me/fcm-token', data: {'fcmToken': token}),
    );
  }

  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    await safeVoid(
      () => client.patch(
        '/users/me/fcm-token',
        data: {'notificationPrefs': prefs},
      ),
    );
  }
}
