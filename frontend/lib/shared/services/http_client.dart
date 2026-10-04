import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/utils/media_url.dart';

const httpRequestTimeout = Duration(seconds: 10);

class LoggingInterceptor extends Interceptor {
  String _safeUri(Uri uri) => uri.replace(query: '', fragment: '').toString();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${options.method} ${_safeUri(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] ${response.statusCode} ${_safeUri(response.requestOptions.uri)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP ERROR] ${err.response?.statusCode} ${_safeUri(err.requestOptions.uri)}',
      );
      debugPrint('[HTTP ERROR TYPE] ${err.type}');
      if (err.type == DioExceptionType.connectionError) {
        debugPrint(
          '[HTTP ERROR HINT] No route to backend. USB/emulador: adb reverse tcp:3000 tcp:3000. Wi-Fi: --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3000',
        );
      }
    }
    handler.next(err);
  }
}

/// Configured Dio HTTP client for API communication
class HttpClient {
  static Dio? _instance;
  static VoidCallback? onAuthLost;
  static _RefreshFlight? _refreshFlight;
  static int _sessionGeneration = 0;
  static bool _refreshSuspended = false;
  static const _originGenerationKey = 'auth_origin_generation';
  static const _authRetryKey = 'auth_retry';
  static const preserveCapturedAuthKey = 'preserve_captured_auth';
  static const capturedAuthTokenKey = 'captured_auth_token';
  static const disableRefreshKey = 'disable_refresh';

  static void invalidateSession() {
    suspendRefresh();
  }

  static void suspendRefresh() {
    _sessionGeneration++;
    _refreshSuspended = true;
  }

  static void establishSession() {
    _sessionGeneration++;
    _refreshSuspended = false;
  }

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: httpRequestTimeout,
        receiveTimeout: httpRequestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor first
    dio.interceptors.add(LoggingInterceptor());

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (!response.requestOptions.path.startsWith('/uploads')) {
            response.data = absolutizeMediaUrls(response.data);
          }
          handler.next(response);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final options = error.requestOptions;
          final retries = options.extra['transient_retry_count'];
          final retryCount = retries is int ? retries : 0;
          final status = error.response?.statusCode;
          final retryableStatus =
              status == 502 || status == 503 || status == 504;
          final retryableFailure =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout;
          final generationValue = options.extra[_originGenerationKey];
          final generation = generationValue is int
              ? generationValue
              : _sessionGeneration;
          if (options.method.toUpperCase() != 'GET' ||
              retryCount >= 2 ||
              !(retryableStatus || retryableFailure) ||
              options.cancelToken?.isCancelled == true ||
              !_isCurrent(generation)) {
            return handler.next(error);
          }

          final delayMs = 200 * (1 << retryCount) + Random().nextInt(100);
          options.extra['transient_retry_count'] = retryCount + 1;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          if (options.cancelToken?.isCancelled == true ||
              !_isCurrent(generation)) {
            return handler.next(error);
          }
          try {
            handler.resolve(await dio.fetch<Object?>(options));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );

    // Auth interceptor — inject JWT token + refresh on 401
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final captured = options.extra[_originGenerationKey];
          final generation = captured is int ? captured : _sessionGeneration;
          options.extra[_originGenerationKey] = generation;
          final token = await StorageService.getToken();
          if (options.extra[_authRetryKey] == true && !_isCurrent(generation)) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          }
          final capturedAuth = options.extra[capturedAuthTokenKey];
          if (options.extra[preserveCapturedAuthKey] == true &&
              capturedAuth is String) {
            options.headers['Authorization'] = 'Bearer $capturedAuth';
          } else if (_isCurrent(generation) &&
              options.extra[_originGenerationKey] == generation &&
              token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final captured = error.requestOptions.extra[_originGenerationKey];
          final generation = captured is int ? captured : _sessionGeneration;

          if (error.requestOptions.extra[disableRefreshKey] == true) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 404 &&
              error.requestOptions.path.contains('/users/me')) {
            await _notifyAuthLostIfCurrent(generation);
            return handler.next(error);
          }

          if (error.response?.statusCode == 401 &&
              error.requestOptions.path.contains('/auth/biometric-login')) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh') &&
              !error.requestOptions.path.contains('/auth/login')) {
            final refreshToken = await StorageService.getRefreshToken();
            if (!_isCurrent(generation)) {
              return handler.next(error);
            }
            if (refreshToken != null) {
              final refreshed = await _refreshSession(
                dio,
                refreshToken,
                generation,
              );
              if (!_isCurrent(generation) || refreshed == null) {
                return handler.next(error);
              }

              final opts = error.requestOptions;
              if (!_isCurrent(generation) ||
                  opts.extra[_originGenerationKey] != generation) {
                return handler.next(error);
              }
              opts.headers['Authorization'] = 'Bearer ${refreshed.token}';
              opts.extra[_authRetryKey] = true;
              try {
                final retryResponse = await dio.fetch(opts);
                if (!_isCurrent(generation) ||
                    opts.extra[_originGenerationKey] != generation) {
                  return handler.next(error);
                }
                return handler.resolve(retryResponse);
              } catch (_) {
                await _notifyAuthLostIfCurrent(generation);
                return handler.next(error);
              }
            }
            await _notifyAuthLostIfCurrent(generation);
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Future<_TokenPair?> _refreshSession(
    Dio dio,
    String refreshToken,
    int generation,
  ) {
    if (_refreshSuspended || generation != _sessionGeneration) {
      return Future.value();
    }
    final current = _refreshFlight;
    if (current != null &&
        current.generation == generation &&
        current.refreshToken == refreshToken) {
      return current.future;
    }
    final future = _performRefresh(dio, refreshToken, generation);
    final flight = _RefreshFlight(generation, refreshToken, future);
    _refreshFlight = flight;
    return future.whenComplete(() {
      if (identical(_refreshFlight, flight)) {
        _refreshFlight = null;
      }
    });
  }

  static Future<_TokenPair?> _performRefresh(
    Dio dio,
    String refreshToken,
    int generation,
  ) async {
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );
      final response = await refreshDio.post('/auth/refresh');
      final data = response.data['data'];
      final pair = _TokenPair(
        data['token'] as String,
        data['refreshToken'] as String,
      );
      if (!_isCurrent(generation)) return null;
      await StorageService.saveTokenPair(pair.token, pair.refreshToken);
      if (!_isCurrent(generation)) {
        await StorageService.clearTokenIf(pair.token);
        await StorageService.clearRefreshTokenIf(pair.refreshToken);
        return null;
      }
      return pair;
    } catch (_) {
      await _notifyAuthLostIfCurrent(generation);
      return null;
    }
  }

  static Future<void> _notifyAuthLostIfCurrent(int expectedGeneration) async {
    await AuthSessionCoordinator.serialize(() async {
      if (!_isCurrent(expectedGeneration)) return;
      _sessionGeneration++;
      _refreshSuspended = true;
      await StorageService.clearTokens();
      onAuthLost?.call();
    });
  }

  static bool _isCurrent(int generation) =>
      generation == _sessionGeneration && !_refreshSuspended;
}

class _TokenPair {
  final String token;
  final String refreshToken;

  const _TokenPair(this.token, this.refreshToken);
}

class _RefreshFlight {
  final int generation;
  final String refreshToken;
  final Future<_TokenPair?> future;

  const _RefreshFlight(this.generation, this.refreshToken, this.future);
}
