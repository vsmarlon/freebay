import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';

class _CapturingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout preserves the captured bearer and does not refresh on 401',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'access-token',
        'refresh_token': 'refresh-token',
        'biometric_token': 'biometric-token',
      });
      HttpClient.establishSession();
      final adapter = _CapturingAdapter();
      HttpClient.instance.httpClientAdapter = adapter;

      await AuthRepository().logout();

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-token',
      );
      expect(await StorageService.getToken(), isNull);
    },
  );
}
