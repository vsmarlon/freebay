import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/http_client.dart';

typedef NotificationSocketFactory =
    NotificationSocketClient Function(String url, String token);

abstract interface class NotificationSocketClient {
  void connect();
  void dispose();
  void onConnect(void Function(dynamic) callback);
  void on(String event, void Function(dynamic) callback);
}

class _IoNotificationSocketClient implements NotificationSocketClient {
  _IoNotificationSocketClient(this._socket);

  final io.Socket _socket;

  @override
  void connect() => _socket.connect();

  @override
  void dispose() => _socket.dispose();

  @override
  void onConnect(void Function(dynamic) callback) =>
      _socket.onConnect(callback);

  @override
  void on(String event, void Function(dynamic) callback) =>
      _socket.on(event, callback);
}

sealed class NotificationSocketEvent {
  const NotificationSocketEvent();
}

class PrivateContentInvalidated extends NotificationSocketEvent {
  const PrivateContentInvalidated();
}

class NotificationSocketReconnected extends NotificationSocketEvent {
  const NotificationSocketReconnected();
}

class NotificationSocketSuspended extends NotificationSocketEvent {
  const NotificationSocketSuspended();
}

class NotificationSocketService with WidgetsBindingObserver {
  NotificationSocketService({
    Future<String?> Function()? tokenReader,
    NotificationSocketFactory? socketFactory,
  }) : _tokenReader = tokenReader ?? StorageService.getToken,
       _socketFactory = socketFactory ?? _createSocket;

  final Future<String?> Function() _tokenReader;
  final NotificationSocketFactory _socketFactory;
  final StreamController<NotificationSocketEvent> _events =
      StreamController<NotificationSocketEvent>.broadcast(sync: true);
  NotificationSocketClient? _socket;
  String? _socketToken;
  Future<void>? _connection;
  int _generation = 0;
  bool _wanted = false;
  bool _disposed = false;
  bool _recoveringAuth = false;

  Stream<NotificationSocketEvent> get events => _events.stream;

  static NotificationSocketClient _createSocket(String url, String token) =>
      _IoNotificationSocketClient(
        io.io(url, <String, dynamic>{
          'forceNew': true,
          'auth': {'token': token},
          'transports': ['websocket'],
          'autoConnect': false,
        }),
      );

  String get _url =>
      '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/notifications';

  Future<void> connect() {
    if (_disposed) return Future<void>.value();
    if (!_wanted) WidgetsBinding.instance.addObserver(this);
    _wanted = true;
    final pending = _connection;
    if (pending != null) return pending;
    final generation = _generation;
    final operation = _connect(generation);
    _connection = operation;
    return operation.whenComplete(() {
      if (identical(_connection, operation)) _connection = null;
    });
  }

  Future<void> _connect(int generation) async {
    String? token;
    try {
      token = await _tokenReader();
    } catch (_) {
      return;
    }
    if (!_isCurrent(generation) || token == null) return;
    if (_socket != null && _socketToken == token) return;
    _socket?.dispose();
    late final NotificationSocketClient socket;
    try {
      socket = _socketFactory(_url, token);
    } catch (_) {
      return;
    }
    _socket = socket;
    _socketToken = token;
    socket
      ..onConnect((_) {
        if (!_isCurrent(generation) || !identical(socket, _socket)) return;
        _events.add(const NotificationSocketReconnected());
      })
      ..on('disconnect', (reason) {
        if (!_isCurrent(generation) || !identical(socket, _socket)) return;
        _events.add(const NotificationSocketSuspended());
        final message = reason.toString().toLowerCase();
        if (message.contains('jwt') ||
            message.contains('io server disconnect')) {
          unawaited(_recoverExpiredToken(socket, generation));
        } else {
          unawaited(connect());
        }
      })
      ..on('connect_error', (error) {
        if (!_isCurrent(generation) || !identical(socket, _socket)) return;
        _events.add(const NotificationSocketSuspended());
        if (error.toString().toLowerCase().contains('jwt')) {
          unawaited(_recoverExpiredToken(socket, generation));
        } else {
          unawaited(connect());
        }
      })
      ..on('private_content_invalidated', (payload) {
        if (!_isCurrent(generation) || !identical(socket, _socket)) return;
        if (payload is Map && payload.isEmpty) {
          _events.add(const PrivateContentInvalidated());
        }
      });
    if (_isCurrent(generation)) socket.connect();
  }

  Future<void> _recoverExpiredToken(
    NotificationSocketClient socket,
    int generation,
  ) async {
    if (_recoveringAuth ||
        !_isCurrent(generation) ||
        !identical(socket, _socket)) {
      return;
    }
    _recoveringAuth = true;
    try {
      if (await HttpClient.refreshCurrentSession() &&
          _isCurrent(generation) &&
          identical(socket, _socket)) {
        await reconnectWithFreshToken();
      } else if (_isCurrent(generation) && identical(socket, _socket)) {
        disconnect();
      }
    } finally {
      _recoveringAuth = false;
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && _wanted && generation == _generation;

  void disconnect() {
    if (_disposed) return;
    _wanted = false;
    _generation++;
    _events.add(const NotificationSocketSuspended());
    _connection = null;
    _socket?.dispose();
    _socket = null;
    _socketToken = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> reconnectWithFreshToken() async {
    disconnect();
    await connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_wanted || _disposed) return;
    if (state == AppLifecycleState.resumed) {
      _events.add(const PrivateContentInvalidated());
      unawaited(reconnectWithFreshToken());
    } else {
      _events.add(const NotificationSocketSuspended());
    }
  }

  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _events.close();
  }
}

final notificationSocketServiceProvider = Provider<NotificationSocketService>((
  ref,
) {
  final service = NotificationSocketService();
  ref.onDispose(service.dispose);
  return service;
});
