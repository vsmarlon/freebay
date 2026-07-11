import 'package:freebay/features/notifications/data/entities/notification_entity.dart';

abstract class INotificationRepository {
  Future<List<NotificationEntity>> getNotifications({
    int limit = 20,
    int offset = 0,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> updateFcmToken(String token);
  Future<void> updateNotificationPrefs(Map<String, bool> prefs);
}
