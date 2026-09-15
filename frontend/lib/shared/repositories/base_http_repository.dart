import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/services/http_client.dart';

/// Base class providing type-safe, DRY network methods for repositories.
abstract class BaseHttpRepository {
  final Dio client;

  BaseHttpRepository({Dio? client}) : client = client ?? HttpClient.instance;

  /// Safely extracts data using dot notation (e.g. 'data.user' or 'data.posts').
  dynamic _extract(dynamic root, String? path) {
    if (path == null || path.isEmpty) {
      if (root is Map && root.containsKey('data')) {
        return root['data'];
      }
      return root;
    }
    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  Either<Failure, T> _mapSingle<T>(
    dynamic extracted, {
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
  }) {
    if (customMapper != null) {
      return Right(customMapper(extracted));
    }
    if (fromJson != null) {
      if (extracted is Map<String, dynamic>) {
        return Right(fromJson(extracted));
      }
      if (extracted is Map) {
        return Right(fromJson(Map<String, dynamic>.from(extracted)));
      }
      return const Left(ServerFailure('Resposta inválida do servidor.'));
    }
    return Right(extracted as T);
  }

  /// Core template execution wrapper.
  Future<Either<Failure, T>> safeCall<T>(
    Future<Response> Function() request, {
    required FutureOr<Either<Failure, T>> Function(Response response) onSuccess,
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
        return onSuccess(response);
      }
      return const Left(ServerFailure());
    } on DioException catch (e) {
      if (kDebugMode && debugLabel != null) {
        debugPrint('[$debugLabel] DioException: ${e.type} ${e.message}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode && debugLabel != null) {
        debugPrint('[$debugLabel] error: $e');
        debugPrint('[$debugLabel] stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  /// Performs a GET request and maps single entity or raw result.
  Future<Either<Failure, T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? extractKey,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
    String? debugLabel,
  }) {
    return safeCall<T>(
      () =>
          client.get(path, queryParameters: queryParameters, options: options),
      debugLabel: debugLabel ?? 'GET $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, extractKey);
        return _mapSingle(
          extracted,
          fromJson: fromJson,
          customMapper: customMapper,
        );
      },
    );
  }

  /// Performs a GET request against a cursor-paginated endpoint.
  ///
  /// Sends `cursor`/`limit` and parses the shared `{ items, hasMore, nextCursor }`
  /// envelope. Pass `itemsKey` only for a legacy endpoint that still names its
  /// list something else.
  Future<Either<Failure, CursorPage<T>>> safePage<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    String? cursor,
    int? limit,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String itemsKey = 'items',
    String? debugLabel,
  }) {
    return safeGet<CursorPage<T>>(
      path,
      queryParameters: {
        ...?queryParameters,
        'cursor': ?cursor,
        'limit': ?limit,
      },
      options: options,
      extractKey: 'data',
      customMapper: (data) =>
          parseCursorPage<T>(data, fromJson, itemsKey: itemsKey),
      debugLabel: debugLabel,
    );
  }

  /// Performs a GET request and maps a list of entities.
  Future<Either<Failure, List<T>>> safeGetList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? listKey,
    required T Function(Map<String, dynamic> json) fromJson,
    String? debugLabel,
  }) {
    return safeCall<List<T>>(
      () =>
          client.get(path, queryParameters: queryParameters, options: options),
      debugLabel: debugLabel ?? 'GET_LIST $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, listKey);
        if (extracted is List) {
          final list = extracted
              .whereType<Map>()
              .map((item) => fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return Right(list);
        }
        final empty = <T>[];
        return Right(empty);
      },
    );
  }

  /// Performs a POST request.
  Future<Either<Failure, T>> safePost<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? extractKey,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
    String? debugLabel,
  }) {
    return safeCall<T>(
      () => client.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: debugLabel ?? 'POST $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, extractKey);
        return _mapSingle(
          extracted,
          fromJson: fromJson,
          customMapper: customMapper,
        );
      },
    );
  }

  /// Performs a PUT request.
  Future<Either<Failure, T>> safePut<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? extractKey,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
    String? debugLabel,
  }) {
    return safeCall<T>(
      () => client.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: debugLabel ?? 'PUT $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, extractKey);
        return _mapSingle(
          extracted,
          fromJson: fromJson,
          customMapper: customMapper,
        );
      },
    );
  }

  /// Performs a PATCH request.
  Future<Either<Failure, T>> safePatch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? extractKey,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
    String? debugLabel,
  }) {
    return safeCall<T>(
      () => client.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: debugLabel ?? 'PATCH $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, extractKey);
        return _mapSingle(
          extracted,
          fromJson: fromJson,
          customMapper: customMapper,
        );
      },
    );
  }

  /// Performs a DELETE request.
  Future<Either<Failure, T>> safeDelete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? extractKey,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic data)? customMapper,
    String? debugLabel,
  }) {
    return safeCall<T>(
      () => client.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      debugLabel: debugLabel ?? 'DELETE $path',
      onSuccess: (res) {
        final extracted = _extract(res.data, extractKey);
        return _mapSingle(
          extracted,
          fromJson: fromJson,
          customMapper: customMapper,
        );
      },
    );
  }

  /// Performs a void mutation call where successful HTTP 2xx means Right(null).
  Future<Either<Failure, void>> safeVoid(
    Future<Response> Function() call, {
    String? debugLabel,
  }) {
    return safeCall<void>(
      call,
      debugLabel: debugLabel,
      onSuccess: (_) => const Right(null),
    );
  }
}
