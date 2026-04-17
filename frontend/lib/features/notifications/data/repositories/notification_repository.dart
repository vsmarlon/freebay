import 'package:freebay/shared/services/http_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(
      {int limit = 20, int offset = 0}) async {
    final response = await HttpClient.instance.get(
      '/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final payload = response.data;
    final notifications = payload['notifications'] as List<dynamic>? ??
        (payload['data'] is List<dynamic>
            ? payload['data'] as List<dynamic>
            : <dynamic>[]);

    return notifications
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response =
        await HttpClient.instance.get('/notifications/unread-count');
    return response.data['data']['count'] as int;
  }

  Future<void> markAsRead(String notificationId) async {
    await HttpClient.instance.post('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await HttpClient.instance.post('/notifications/read-all');
  }

  Future<void> updateFcmToken(String token) async {
    await HttpClient.instance
        .patch('/users/me/fcm-token', data: {'fcmToken': token});
  }

  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    await HttpClient.instance
        .patch('/users/me/fcm-token', data: {'notificationPrefs': prefs});
  }
}
