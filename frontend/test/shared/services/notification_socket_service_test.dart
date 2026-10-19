import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';

class _FakeSocket implements NotificationSocketClient {
  final callbacks = <String, void Function(dynamic)>{};
  bool disposed = false;

  @override
  void connect() {}

  @override
  void dispose() => disposed = true;

  @override
  void onConnect(void Function(dynamic) callback) =>
      callbacks['connect'] = callback;

  @override
  void on(String event, void Function(dynamic) callback) =>
      callbacks[event] = callback;
}

void main() {
  test(
    'only an empty revocation payload triggers typed invalidation',
    () async {
      final socket = _FakeSocket();
      final service = NotificationSocketService(
        tokenReader: () async => 'token',
        socketFactory: (_, _) => socket,
      );
      addTearDown(service.dispose);
      final events = <NotificationSocketEvent>[];
      final subscription = service.events.listen(events.add);
      addTearDown(subscription.cancel);

      await service.connect();
      socket.callbacks['private_content_invalidated']?.call({'postId': 'leak'});
      socket.callbacks['private_content_invalidated']?.call({});

      expect(events, [isA<PrivateContentInvalidated>()]);
    },
  );

  test(
    'disconnect prevents a pending token read from opening a socket',
    () async {
      final token = Completer<String?>();
      var created = false;
      final service = NotificationSocketService(
        tokenReader: () => token.future,
        socketFactory: (_, _) {
          created = true;
          return _FakeSocket();
        },
      );
      addTearDown(service.dispose);

      final pending = service.connect();
      service.disconnect();
      token.complete('stale-account-token');
      await pending;

      expect(created, isFalse);
    },
  );
}
