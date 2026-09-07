import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/domain/repositories/i_notification_repository.dart';

class NotificationRepository extends BaseHttpRepository
    implements INotificationRepository {
  NotificationRepository({super.client});

  @override
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

  @override
  Future<int> getUnreadCount() async {
    final result = await safeGet<int>(
      '/notifications/unread-count',
      extractKey: 'data.count',
      customMapper: (d) => (d as int?) ?? 0,
    );
    return result.rightOrNull ?? 0;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await safeVoid(() => client.patch('/notifications/$notificationId/read'));
  }

  @override
  Future<void> markAllAsRead() async {
    await safeVoid(() => client.post('/notifications/read-all'));
  }

  @override
  Future<void> updateFcmToken(String token) async {
    await safeVoid(
      () => client.patch('/users/me/fcm-token', data: {'fcmToken': token}),
    );
  }

  @override
  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    await safeVoid(
      () => client.patch(
        '/users/me/fcm-token',
        data: {'notificationPrefs': prefs},
      ),
    );
  }
}
