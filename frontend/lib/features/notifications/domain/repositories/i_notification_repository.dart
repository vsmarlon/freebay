import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';

abstract class INotificationRepository {
  Future<CursorPage<NotificationEntity>> getNotifications({
    String? cursor,
    int limit = 20,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> updateFcmToken(String token);
  Future<void> updateNotificationPrefs(Map<String, bool> prefs);
}
