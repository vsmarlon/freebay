import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';

class _FakeSocket implements ChatSocketClient {
  bool connectedValue = false;
  final emitted = <(String, dynamic)>[];
  final callbacks = <String, void Function(dynamic)>{};

  @override
  bool get connected => connectedValue;

  @override
  void connect() {}

  @override
  void dispose() => connectedValue = false;

  @override
  void emit(String event, [dynamic data]) => emitted.add((event, data));

  @override
  void onConnect(void Function(dynamic) callback) {
    callbacks['connect'] = callback;
  }

  @override
  void onConnectError(void Function(dynamic) callback) {
    callbacks['connect_error'] = callback;
  }

  @override
  void onDisconnect(void Function(dynamic) callback) {
    callbacks['disconnect'] = callback;
  }

  @override
  void on(String event, void Function(dynamic) callback) {
    callbacks[event] = callback;
  }
}

void main() {
  Stream<List<ConnectivityResult>> noConnectivity() => const Stream.empty();

  test('disconnect invalidates a pending token read', () async {
    final token = Completer<String?>();
    var socketsCreated = 0;
    final service = ChatSocketService(
      tokenReader: () => token.future,
      socketFactory: (_, _) {
        socketsCreated++;
        return _FakeSocket();
      },
      connectivityStream: noConnectivity,
    );
    addTearDown(service.dispose);

    final connection = service.connect();
    service.disconnect();
    token.complete('token');
    await connection;

    expect(socketsCreated, 0);
  });

  test('concurrent connects share one pending handshake', () async {
    final token = Completer<String?>();
    var socketsCreated = 0;
    final service = ChatSocketService(
      tokenReader: () => token.future,
      socketFactory: (_, _) {
        socketsCreated++;
        return _FakeSocket();
      },
      connectivityStream: noConnectivity,
    );
    addTearDown(service.dispose);

    final first = service.connect();
    final second = service.connect();
    token.complete('token');
    await Future.wait([first, second]);

    expect(socketsCreated, 1);
  });

  test('old socket callbacks are ignored after token replacement', () async {
    final tokens = <String?>['old-token', 'new-token'];
    final sockets = <_FakeSocket>[];
    var receivedMessages = 0;
    final service = ChatSocketService(
      tokenReader: () async => tokens.removeAt(0),
      socketFactory: (_, _) {
        final socket = _FakeSocket();
        sockets.add(socket);
        return socket;
      },
      connectivityStream: noConnectivity,
    );
    addTearDown(service.dispose);
    final subscription = service.messageStream.listen(
      (_) => receivedMessages++,
    );
    addTearDown(subscription.cancel);

    await service.connect();
    final oldSocket = sockets.single;
    await service.connect();
    final newSocket = sockets.last;
    oldSocket.callbacks['new_message']?.call({'id': 'stale'});
    newSocket.callbacks['connect']?.call(null);

    expect(receivedMessages, 0);
    expect(newSocket.emitted, isEmpty);
  });

  test('disconnect permits a fresh account connection', () async {
    final tokens = <String?>['account-a', 'account-b'];
    final sockets = <_FakeSocket>[];
    final service = ChatSocketService(
      tokenReader: () async => tokens.removeAt(0),
      socketFactory: (_, _) {
        final socket = _FakeSocket();
        sockets.add(socket);
        return socket;
      },
      connectivityStream: noConnectivity,
    );
    addTearDown(service.dispose);

    await service.connect();
    service.disconnect();
    await service.connect();

    expect(sockets, hasLength(2));
  });

  test(
    'rooms rejoin on reconnect and leave on provider-style cleanup',
    () async {
      final socket = _FakeSocket();
      final service = ChatSocketService(
        tokenReader: () async => 'token',
        socketFactory: (_, _) => socket,
        connectivityStream: noConnectivity,
      );
      addTearDown(service.dispose);

      service.joinConversation('conversation-1');
      await service.connect();
      socket.callbacks['connect']?.call(null);
      service.leaveConversation('conversation-1');
      socket.callbacks['connect']?.call(null);
      service.dispose();
      socket.callbacks['connect']?.call(null);

      expect(socket.emitted, hasLength(2));
      expect(socket.emitted[0].$1, 'join_conversation');
      expect(socket.emitted[0].$2['conversationId'], 'conversation-1');
      expect(socket.emitted[1].$1, 'leave_conversation');
      expect(socket.emitted[1].$2['conversationId'], 'conversation-1');
    },
  );
}
