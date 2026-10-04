import 'dart:typed_data';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statuses);

  final List<int> statuses;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final status =
        statuses[requests < statuses.length ? requests : statuses.length - 1];
    requests++;
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await StorageService.init();
    HttpClient.establishSession();
  });

  test('retries transient GET failures at most twice', () async {
    final adapter = _StatusAdapter([503, 503, 200]);
    HttpClient.instance.httpClientAdapter = adapter;

    await HttpClient.instance.get('/retryable');

    expect(adapter.requests, 3);
  });

  test('never replays a mutation after a transient failure', () async {
    final adapter = _StatusAdapter([503, 200]);
    HttpClient.instance.httpClientAdapter = adapter;

    await expectLater(
      HttpClient.instance.post('/mutation'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests, 1);
  });

  test('does not retry a GET after its session generation changes', () async {
    final adapter = _StatusAdapter([503, 200]);
    HttpClient.instance.httpClientAdapter = adapter;
    final request = HttpClient.instance.get('/session-bound');
    HttpClient.suspendRefresh();

    await expectLater(request, throwsA(isA<DioException>()));

    expect(adapter.requests, 1);
  });

  test(
    'removes a cached bearer from requests while the session is suspended',
    () async {
      final adapter = _AuthorizationAdapter();
      HttpClient.instance.options.headers['Authorization'] = 'Bearer stale';
      HttpClient.instance.httpClientAdapter = adapter;
      HttpClient.suspendRefresh();

      await HttpClient.instance.get('/suspended');

      expect(adapter.authorization, isNull);
    },
  );

  test('retries GET connection timeouts', () async {
    final adapter = _TimeoutThenSuccessAdapter();
    HttpClient.instance.httpClientAdapter = adapter;

    await HttpClient.instance.get('/timeout-retry');

    expect(adapter.requests, 2);
  });

  test('does not retry a canceled GET', () async {
    final adapter = _CancelableTimeoutAdapter();
    HttpClient.instance.httpClientAdapter = adapter;
    final cancelToken = CancelToken();
    final request = HttpClient.instance.get<void>(
      '/cancel-retry',
      cancelToken: cancelToken,
    );
    await adapter.started.future;
    cancelToken.cancel();
    adapter.release.complete();

    await expectLater(request, throwsA(isA<DioException>()));

    expect(adapter.requests, 1);
  });
}

class _AuthorizationAdapter implements HttpClientAdapter {
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization = options.headers['Authorization'] as String?;
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _CancelableTimeoutAdapter implements HttpClientAdapter {
  final started = Completer<void>();
  final release = Completer<void>();
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    started.complete();
    await release.future;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TimeoutThenSuccessAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    }
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}
