import 'package:freebay/core/router/app_routes.dart';

class AppLink {
  const AppLink._();

  static String fromNotification(Map<String, dynamic> data) {
    switch (data['action']?.toString()) {
      case 'wallet':
        return AppRoutes.wallet;
      case 'chat':
        return _withId(AppRoutes.chat, data['conversationId'], '/chat');
      case 'profile':
        return AppRoutes.profile;
      case 'orders':
        return _withId(AppRoutes.orders, data['orderId'], '/orders');
      case 'disputes':
        return _withId(AppRoutes.disputes, data['disputeId'], '/disputes');
      default:
        return AppRoutes.notifications;
    }
  }

  static String? fromUri(Uri uri) {
    final segments = [
      ...uri.host.isEmpty || uri.host == 'app' ? <String>[] : [uri.host],
      ...uri.pathSegments,
    ].where((segment) => segment.isNotEmpty).toList();

    if (segments.isEmpty) return null;

    final query = uri.query.isEmpty ? '' : '?${uri.query}';

    switch (segments.first) {
      case 'reset-password':
        return '${AppRoutes.resetPassword}$query';
      case 'products':
        return segments.length > 1
            ? '/products/${segments[1]}'
            : AppRoutes.explore;
      case 'post':
        return segments.length > 1 ? '/post/${segments[1]}' : AppRoutes.feed;
      case 'user':
        return segments.length > 1 ? '/user/${segments[1]}' : AppRoutes.profile;
      case 'orders':
        return segments.length > 1
            ? '/orders/${segments[1]}'
            : AppRoutes.orders;
      case 'chat':
        return segments.length > 1 ? '/chat/${segments[1]}' : AppRoutes.chat;
      case 'disputes':
        return segments.length > 1
            ? '/disputes/${segments[1]}'
            : AppRoutes.disputes;
      default:
        return null;
    }
  }

  static String _withId(String fallback, Object? id, String prefix) {
    final value = id?.toString();
    if (value == null || value.isEmpty) return fallback;
    return '$prefix/$value';
  }
}
