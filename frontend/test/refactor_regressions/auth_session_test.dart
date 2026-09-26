import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, {this.status = 200});

  final Object body;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Dio _client(Object body, {int status = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.httpClientAdapter = _Adapter(body, status: status);
  return dio;
}

const _user = {'id': 'user-1', 'email': 'person@example.com'};

void main() {
  test(
    'installs the shared session and preserves login remember-me behavior',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = AuthRepository(
        client: _client({
          'success': true,
          'data': {'token': 'access', 'refreshToken': 'refresh', 'user': _user},
        }),
      );

      final result = await repository.login(
        'person@example.com',
        'password',
        true,
      );

      expect(result.isRight, isTrue);
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        'access',
      );
      expect(
        await const FlutterSecureStorage().read(key: 'refresh_token'),
        'refresh',
      );
      expect(
        await const FlutterSecureStorage().read(key: 'remember_me'),
        'true',
      );
      expect(
        await const FlutterSecureStorage().read(key: 'saved_email'),
        'person@example.com',
      );
    },
  );

  test(
    'returns the endpoint-specific missing-data failure without installing tokens',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = AuthRepository(
        client: _client({'success': true, 'data': null}),
      );

      final result = await repository.register(
        'person@example.com',
        'password',
        'Person',
        'person',
      );

      expect(result.leftOrNull, isA<ServerFailure>());
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        isNull,
      );
    },
  );
}
