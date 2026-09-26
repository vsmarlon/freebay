import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';

Response<dynamic> _response(int statusCode, dynamic data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/test'),
  statusCode: statusCode,
  data: data,
);

void main() {
  test('awaits an asynchronous decoder', () async {
    final result = await requestEither<int>(
      () async => _response(200, null),
      decoder: (_) async => Right(int.parse('42')),
    );

    expect(result.rightOrNull, 42);
  });

  test('preserves an explicit decoder failure', () async {
    const failure = ServerFailure('invalid payload');
    final result = await requestEither<int>(
      () async => _response(200, null),
      decoder: (_) => const Left(failure),
    );

    expect(result.leftOrNull?.message, 'invalid payload');
  });

  test('maps non-2xx responses to a server failure', () async {
    final result = await requestEither<int>(
      () async => _response(422, null),
      decoder: (_) => const Right(1),
    );

    expect(result.leftOrNull, isA<ServerFailure>());
  });

  test('maps request and asynchronous decoder errors', () async {
    final requestError = await requestEither<int>(
      () async => throw StateError('request failed'),
      decoder: (_) => const Right(1),
    );
    final decoderError = await requestEither<int>(
      () async => _response(200, null),
      decoder: (_) async => throw StateError('decode failed'),
    );

    expect(requestError.leftOrNull, isA<UnknownFailure>());
    expect(decoderError.leftOrNull, isA<UnknownFailure>());
  });
}
