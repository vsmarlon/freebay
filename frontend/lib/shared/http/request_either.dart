import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

Future<Either<Failure, T>> requestEither<T>(
  Future<Response<dynamic>> Function() request, {
  required FutureOr<Either<Failure, T>> Function(Response<dynamic>) decoder,
  String? debugLabel,
}) async {
  try {
    final response = await request();
    if (kDebugMode && debugLabel != null) {
      debugPrint('[$debugLabel] status: ${response.statusCode}');
    }
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return await decoder(response);
    }
    return const Left(ServerFailure());
  } on DioException catch (error) {
    if (kDebugMode && debugLabel != null) {
      debugPrint('[$debugLabel] DioException: ${error.type} ${error.message}');
    }
    return Left(mapDioExceptionToFailure(error));
  } catch (error, stack) {
    if (kDebugMode && debugLabel != null) {
      debugPrint('[$debugLabel] error: $error');
      debugPrint('[$debugLabel] stack: $stack');
    }
    return const Left(UnknownFailure());
  }
}
