import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/errors/error_messages.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

DioException _badResponse(int status, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  const leak =
      'Invalid `prisma.product.findUnique()` invocation in /app/src/x.ts:42';

  test('never surfaces the server message, whatever the status', () {
    for (final status in [400, 401, 403, 404, 409, 422, 429, 500, 502, 503]) {
      final failure = mapDioExceptionToFailure(
        _badResponse(status, {
          'error': {'code': 'DB_ERROR', 'message': leak},
          'message': leak,
        }),
      );
      expect(
        failure.message,
        isNot(contains('prisma')),
        reason: 'status $status leaked the backend message',
      );
    }
  });

  test('maps a known code to its local copy', () {
    final failure = mapDioExceptionToFailure(
      _badResponse(401, {
        'error': {'code': 'INVALID_CREDENTIALS', 'message': leak},
      }),
    );
    expect(failure.message, 'Email ou senha incorretos.');
  });

  test('falls back to the status generic for an unknown code', () {
    final failure = mapDioExceptionToFailure(
      _badResponse(404, {
        'error': {'code': 'SOMETHING_NEW', 'message': leak},
      }),
    );
    expect(failure, isA<NotFoundFailure>());
    expect(failure.message, 'Recurso não encontrado.');
  });

  test('userMessageOf hides anything that is not a Failure', () {
    expect(userMessageOf(Exception(leak)), kGenericErrorMessage);
    expect(userMessageOf(leak), kGenericErrorMessage);
    expect(userMessageOf(null), kGenericErrorMessage);
    expect(
      userMessageOf(const NetworkFailure()),
      'Sem conexão com a internet.',
    );
  });
}
