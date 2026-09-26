import 'package:freebay/shared/models/cursor_page.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/notifications/data/entities/notification_entity.dart';

class NotificationRepository {
  final Dio client;

  NotificationRepository({Dio? client})
    : client = client ?? HttpClient.instance;

  Future<CursorPage<NotificationEntity>> getNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    final result = await requestEither(
      () => client.get(
        '/notifications',
        queryParameters: {'cursor': ?cursor, 'limit': limit},
      ),
      decoder: (response) => Right(
        parseCursorPage<NotificationEntity>(
          response.data['data'],
          NotificationEntity.fromJson,
        ),
      ),
    );
    return result.rightOrNull ?? const CursorPage<NotificationEntity>.empty();
  }

  Future<int> getUnreadCount() async {
    final result = await requestEither(
      () => client.get('/notifications/unread-count'),
      decoder: (response) =>
          Right((response.data['data']['count'] as int?) ?? 0),
    );
    return result.rightOrNull ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await requestEither<void>(
      () => client.patch('/notifications/$notificationId/read'),
      decoder: (_) => const Right(null),
    );
  }

  Future<void> markAllAsRead() async {
    await requestEither<void>(
      () => client.post('/notifications/read-all'),
      decoder: (_) => const Right(null),
    );
  }

  Future<void> updateFcmToken(String token) async {
    await requestEither<void>(
      () => client.patch('/users/me/fcm-token', data: {'fcmToken': token}),
      decoder: (_) => const Right(null),
    );
  }

  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    await requestEither<void>(
      () => client.patch(
        '/users/me/fcm-token',
        data: {'notificationPrefs': prefs},
      ),
      decoder: (_) => const Right(null),
    );
  }
}
