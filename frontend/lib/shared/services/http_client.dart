import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/services/storage_service.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP] ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('[BODY] ${_prettyJson(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
      if (response.data != null) {
        debugPrint('[BODY] ${_prettyJson(response.data)}');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '[HTTP ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('[HTTP ERROR TYPE] ${err.type}');
      if (err.type == DioExceptionType.connectionError) {
        debugPrint(
          '[HTTP ERROR HINT] If you are on a physical device, do not use localhost. Run with --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3000',
        );
      }
      if (err.response?.data != null) {
        debugPrint('[ERROR_BODY] ${_prettyJson(err.response?.data)}');
      }
    }
    handler.next(err);
  }

  String _prettyJson(dynamic json) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}

/// Configured Dio HTTP client for API communication
class HttpClient {
  static Dio? _instance;
  static VoidCallback? onAuthLost;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor first
    dio.interceptors.add(LoggingInterceptor());

    // Auth interceptor — inject JWT token + refresh on 401
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh') &&
              !error.requestOptions.path.contains('/auth/login')) {
            final refreshToken = await StorageService.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshDio = Dio(BaseOptions(
                  baseUrl: dio.options.baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $refreshToken',
                  },
                ));
                final response = await refreshDio.post('/auth/refresh');
                final data = response.data['data'];
                final newToken = data['token'] as String;
                final newRefreshToken = data['refreshToken'] as String;
                await StorageService.saveToken(newToken);
                await StorageService.saveRefreshToken(newRefreshToken);

                // Retry original request with new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await dio.fetch(opts);
                return handler.resolve(retryResponse);
              } catch (_) {
                await StorageService.clearTokens();
                onAuthLost?.call();
                return handler.next(error);
              }
            }
            await StorageService.clearTokens();
            onAuthLost?.call();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  Future<Response> get(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return instance.get(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return instance.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return instance.put(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return instance.delete(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return instance.patch(path,
        data: data, queryParameters: queryParameters, options: options);
  }
}
