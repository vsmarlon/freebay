import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';
import 'package:freebay/features/notifications/domain/repositories/i_notification_repository.dart';

class NotificationRepository extends BaseHttpRepository
    implements INotificationRepository {
  NotificationRepository({super.client});

  @override
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await safeGetList<NotificationEntity>(
      '/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
      listKey: 'data.notifications',
      fromJson: NotificationEntity.fromJson,
    );
    return result.rightOrNull ?? <NotificationEntity>[];
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
    await safeVoid(() => client.post('/notifications/$notificationId/read'));
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
