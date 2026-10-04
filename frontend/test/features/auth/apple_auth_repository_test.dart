import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';

class _AppleAuthAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    body = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'token': 'apple-access',
          'refreshToken': 'apple-refresh',
          'user': {'id': 'apple-user', 'email': 'apple@example.com'},
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'Apple authentication posts the backend contract and installs its session',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final adapter = _AppleAuthAdapter();
      final client = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;

      final result = await AuthRepository(client: client).appleAuth(
        identityToken: 'identity-token',
        authorizationCode: 'authorization-code',
        rawNonce: 'original-raw-nonce',
        authenticationAttempt: AuthSessionCoordinator.beginAuthentication(),
        fullName: 'First Last',
      );

      expect(result.rightOrNull?.id, 'apple-user');
      expect(adapter.path, '/auth/apple');
      expect(adapter.body, {
        'identityToken': 'identity-token',
        'authorizationCode': 'authorization-code',
        'rawNonce': 'original-raw-nonce',
        'fullName': 'First Last',
      });
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        'apple-access',
      );
      expect(
        await const FlutterSecureStorage().read(key: 'refresh_token'),
        'apple-refresh',
      );
      expect(
        await const FlutterSecureStorage().read(key: 'remember_me'),
        'true',
      );
    },
  );
}
