import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/router/app_link.dart';
import 'package:freebay/core/router/app_routes.dart';

void main() {
  test('notification links route current and type-only legacy payloads', () {
    final cases = <({Map<String, dynamic> data, String route})>[
      (data: {'action': 'wallet'}, route: AppRoutes.wallet),
      (
        data: {'action': 'post', 'postId': 'post-1'},
        route: AppRoutes.postPath('post-1'),
      ),
      (
        data: {'action': 'post', 'postId': 'post-1', 'commentId': 'comment-2'},
        route: AppRoutes.commentPath('post-1', 'comment-2'),
      ),
      (
        data: {'action': 'disputes', 'disputeId': 'dispute-1'},
        route: AppRoutes.disputePath('dispute-1'),
      ),
      (data: {'type': 'PAYMENT'}, route: AppRoutes.wallet),
      (
        data: {'type': 'ORDER', 'orderId': 'order-1'},
        route: AppRoutes.orderPath('order-1'),
      ),
      (
        data: {'type': 'MESSAGE', 'conversationId': 'chat-1'},
        route: AppRoutes.chatPath('chat-1'),
      ),
      (
        data: {'type': 'MESSAGE', 'orderId': 'order-1'},
        route: AppRoutes.chatPath('order-1'),
      ),
      (
        data: {'type': 'FOLLOW', 'senderId': 'user-1'},
        route: AppRoutes.userPath('user-1'),
      ),
      (
        data: {'type': 'DISPUTE', 'disputeId': 'dispute-1'},
        route: AppRoutes.disputePath('dispute-1'),
      ),
      (
        data: {'type': 'DISPUTE', 'orderId': 'order-1'},
        route: AppRoutes.orderPath('order-1'),
      ),
    ];

    for (final testCase in cases) {
      expect(
        AppLink.fromNotification(testCase.data),
        testCase.route,
        reason: '${testCase.data}',
      );
    }
  });

  test('reply deep links open the exact reply context', () {
    expect(
      AppLink.fromUri(Uri.parse('freebay://app/post/post-1/comment/comment-2')),
      AppRoutes.commentPath('post-1', 'comment-2'),
    );
  });

  test('malformed, ambiguous, and unknown destinations stay in the inbox', () {
    final cases = <Map<String, dynamic>>[
      {'action': 'post', 'postId': 'post/1'},
      {'action': 'post', 'postId': 42},
      {'action': 'profile', 'userId': '/profile?x'},
      {
        'action': 'chat',
        'conversationId': {'id': 'chat-1'},
      },
      {'action': 'orders', 'orderId': 'order#1'},
      {'action': 'disputes', 'disputeId': 'dispute 1'},
      {'action': 'post', 'entityId': 'comment-1'},
      {'action': 'unknown', 'type': 'PAYMENT'},
      {'type': 'FOLLOW'},
      {'type': 'UNKNOWN'},
    ];

    for (final data in cases) {
      expect(
        AppLink.fromNotification(data),
        AppRoutes.notifications,
        reason: '$data',
      );
    }
  });
}
