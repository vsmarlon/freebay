import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';

class _PrivacyAdapter implements HttpClientAdapter {
  final requests = <(String, String)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((options.method, options.path));
    if (options.path == '/users/me/export' || options.path == '/users/me') {
      expect(options.headers['x-step-up-token'], 'fresh-proof');
    }
    final body = switch (options.path) {
      '/users/me/export' => {
        'success': true,
        'data': {
          'profile': {'id': 'u'},
        },
      },
      '/users/me' => {
        'success': true,
        'data': {'deletionRequestedAt': '2026-10-01T00:00:00.000Z'},
      },
      _ => {'success': true, 'data': {}},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
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
    'privacy actions use the current account endpoints and parse request date',
    () async {
      final adapter = _PrivacyAdapter();
      final client = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final repository = ProfileRepository(client: client);

      final export = await repository.exportMyData(stepUpToken: 'fresh-proof');
      final deletion = await repository.requestAccountDeletion(
        stepUpToken: 'fresh-proof',
      );
      final cancel = await repository.cancelAccountDeletion();
      final report = await repository.reportUser('user-2', reason: 'SPAM');

      expect(export.rightOrNull?['profile'], {'id': 'u'});
      expect(
        deletion.rightOrNull?.toIso8601String(),
        '2026-10-01T00:00:00.000Z',
      );
      expect(cancel.isRight, isTrue);
      expect(report.isRight, isTrue);
      expect(adapter.requests, [
        ('GET', '/users/me/export'),
        ('DELETE', '/users/me'),
        ('PATCH', '/users/me/deletion/cancel'),
        ('POST', '/reports'),
      ]);
    },
  );
}
