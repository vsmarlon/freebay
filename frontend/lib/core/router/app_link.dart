import 'package:freebay/core/router/app_routes.dart';

class AppLink {
  const AppLink._();

  static String fromNotification(Map<String, dynamic> data) {
    String? id(String key) {
      final candidate = data[key];
      if (candidate is! String ||
          !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(candidate)) {
        return null;
      }
      return candidate;
    }

    final action = data['action'];
    if (action != null && action is! String) return AppRoutes.notifications;
    final routeAction =
        action ??
        switch (data['type']) {
          'PAYMENT' => 'wallet',
          'ORDER' => 'orders',
          'MESSAGE' => 'chat',
          'FOLLOW' => 'profile',
          'DISPUTE' => 'disputes',
          _ => null,
        };

    switch (routeAction) {
      case 'wallet':
        return AppRoutes.wallet;
      case 'chat':
        final conversationId =
            id('conversationId') ??
            (data['conversationId'] == null ? id('orderId') : null);
        if (conversationId != null) return AppRoutes.chatPath(conversationId);
        return data['conversationId'] == null && data['orderId'] == null
            ? AppRoutes.chat
            : AppRoutes.notifications;
      case 'profile':
        final userId = id(action == null ? 'senderId' : 'userId');
        return userId == null
            ? AppRoutes.notifications
            : AppRoutes.userPath(userId);
      case 'post':
        final postId = id('postId');
        final commentId = id('commentId');
        if (postId != null && commentId != null) {
          return AppRoutes.commentPath(postId, commentId);
        }
        return postId == null
            ? AppRoutes.notifications
            : AppRoutes.postPath(postId);
      case 'orders':
        final orderId = id('orderId');
        return orderId == null
            ? AppRoutes.notifications
            : AppRoutes.orderPath(orderId);
      case 'disputes':
        final disputeId = id('disputeId');
        if (disputeId != null) return AppRoutes.disputePath(disputeId);
        if (action == null) {
          final orderId = id('orderId');
          if (orderId != null) return AppRoutes.orderPath(orderId);
        }
        return AppRoutes.notifications;
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
        if (segments.length == 4 &&
            segments[2] == 'comment' &&
            RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segments[1]) &&
            RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segments[3])) {
          return AppRoutes.commentPath(segments[1], segments[3]);
        }
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
