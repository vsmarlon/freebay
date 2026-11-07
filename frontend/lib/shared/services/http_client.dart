import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/utils/media_url.dart';

const httpRequestTimeout = Duration(seconds: 10);

String sanitizeHttpRoute(String path) {
  const routeNames = {
    'auth',
    'login',
    'logout',
    'refresh',
    'register',
    'google',
    'apple',
    'biometric-login',
    'biometric-challenge',
    'users',
    'me',
    'profile',
    'cart',
    'orders',
    'posts',
    'stories',
    'chat',
    'conversations',
    'notifications',
    'wallet',
    'products',
    'search',
    'upload',
  };
  final cleanPath = path.split(RegExp(r'[?#]')).first;
  final parts = cleanPath.split('/').where((part) => part.isNotEmpty);
  return '/${parts.map((part) => routeNames.contains(part) ? part : ':id').join('/')}';
}

String _authPhase(RequestOptions options) {
  final route = sanitizeHttpRoute(options.path);
  if (route.startsWith('/auth/')) return route.substring('/auth/'.length);
  if (route == '/users/me') return 'session-validation';
  return 'request';
}

class LoggingInterceptor extends Interceptor {
  final Map<RequestOptions, Stopwatch> _timers = Map.identity();

  bool get _enabled => !kReleaseMode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      _timers[options] = Stopwatch()..start();
      debugPrint(
        '[HTTP] ${options.method} ${sanitizeHttpRoute(options.path)} phase=${_authPhase(options)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      final elapsed = _timers
          .remove(response.requestOptions)
          ?.elapsedMilliseconds;
      debugPrint(
        '[HTTP] ${response.requestOptions.method} ${sanitizeHttpRoute(response.requestOptions.path)} ${response.statusCode} ${elapsed ?? 0}ms phase=${_authPhase(response.requestOptions)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      final options = err.requestOptions;
      final elapsed = _timers.remove(options)?.elapsedMilliseconds;
      debugPrint(
        '[HTTP ERROR] ${options.method} ${sanitizeHttpRoute(options.path)} ${err.response?.statusCode ?? 'network'} ${elapsed ?? 0}ms ${err.type} phase=${_authPhase(options)}',
      );
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

  /// Endpoints callable without a session. A 401 there means the credentials
  /// presented are wrong, never that the current session expired.
  static const _publicAuthPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/google',
    '/auth/apple',
    '/auth/forgot-password',
    '/auth/verify-reset-code',
    '/auth/reset-password',
    '/auth/username-available',
    '/auth/biometric-login',
    '/auth/biometric-challenge',
  };

  static bool _isPublicAuthRequest(String path) =>
      _publicAuthPaths.contains(path.split(RegExp(r'[?#]')).first);

  static String? _errorCode(Object? body) => switch (body) {
    {'error': {'code': final String code}} => code,
    _ => null,
  };

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
      InterceptorsWrapper(
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

          if (error.requestOptions.extra[disableRefreshKey] == true ||
              error.requestOptions.extra[_authRetryKey] == true) {
            return handler.next(error);
          }

          if (_isPublicAuthRequest(error.requestOptions.path)) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 404 &&
              error.requestOptions.path.contains('/users/me')) {
            if (_errorCode(error.response?.data) == 'USER_NOT_FOUND') {
              await _notifyAuthLostIfCurrent(generation);
            }
            return handler.next(error);
          }

          if (error.type == DioExceptionType.badResponse &&
              error.response?.statusCode == 401 &&
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
              final body = opts.data;
              if (body is FormData && body.isFinalized) {
                try {
                  opts.data = body.clone();
                } catch (_) {
                  return handler.next(error);
                }
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
              } on DioException catch (_) {
                // A 401 on the retried request is a business rejection, not
                // session loss. Only a 401 from /auth/refresh is (see
                // _performRefresh), so no auth-lost notification here.
                return handler.next(error);
              } catch (_) {
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

  static Future<bool> refreshCurrentSession() async {
    final generation = _sessionGeneration;
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null || !_isCurrent(generation)) return false;
    return await _refreshSession(instance, refreshToken, generation) != null;
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
      final response = await dio.post<Object?>(
        '/auth/refresh',
        options: Options(
          extra: {
            disableRefreshKey: true,
            preserveCapturedAuthKey: true,
            capturedAuthTokenKey: refreshToken,
          },
        ),
      );
      final data = response.data! as Map<String, Object?>;
      final envelope = data['data']! as Map<String, Object?>;
      final pair = _TokenPair(
        envelope['token'] as String,
        envelope['refreshToken'] as String,
      );
      if (!_isCurrent(generation)) return null;
      await StorageService.saveTokenPair(pair.token, pair.refreshToken);
      if (!_isCurrent(generation)) {
        await StorageService.clearTokenIf(pair.token);
        await StorageService.clearRefreshTokenIf(pair.refreshToken);
        return null;
      }
      return pair;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _notifyAuthLostIfCurrent(generation);
      }
      return null;
    } catch (_) {
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
