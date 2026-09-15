import 'package:freebay/core/router/app_routes.dart';

class AppLink {
  const AppLink._();

  static String fromNotification(Map<String, dynamic> data) {
    switch (data['action']?.toString()) {
      case 'wallet':
        return AppRoutes.wallet;
      case 'chat':
        return data['conversationId']?.toString().isNotEmpty == true
            ? AppRoutes.chatPath(data['conversationId'].toString())
            : AppRoutes.chat;
      case 'profile':
        return AppRoutes.profile;
      case 'orders':
        return data['orderId']?.toString().isNotEmpty == true
            ? AppRoutes.orderPath(data['orderId'].toString())
            : AppRoutes.orders;
      case 'disputes':
        return data['disputeId']?.toString().isNotEmpty == true
            ? AppRoutes.disputePath(data['disputeId'].toString())
            : AppRoutes.disputes;
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
            ? AppRoutes.productPath(segments[1])
            : AppRoutes.explore;
      case 'post':
        return segments.length > 1
            ? AppRoutes.postPath(segments[1])
            : AppRoutes.feed;
      case 'user':
        return segments.length > 1
            ? AppRoutes.userPath(segments[1])
            : AppRoutes.profile;
      case 'orders':
        return segments.length > 1
            ? AppRoutes.orderPath(segments[1])
            : AppRoutes.orders;
      case 'chat':
        return segments.length > 1
            ? AppRoutes.chatPath(segments[1])
            : AppRoutes.chat;
      case 'disputes':
        return segments.length > 1
            ? AppRoutes.disputePath(segments[1])
            : AppRoutes.disputes;
      default:
        return null;
    }
  }
}
