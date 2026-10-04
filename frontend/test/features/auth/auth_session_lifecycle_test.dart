import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final loginAStarted = Completer<void>();
  final loginAResponse = Completer<ResponseBody>();
  final loginBStarted = Completer<void>();
  final currentUserStarted = Completer<void>();
  final currentUserResponse = Completer<ResponseBody>();
  final completeProfileStarted = Completer<void>();
  final completeProfileResponse = Completer<ResponseBody>();
  int loginCount = 0;
  bool holdCurrentUser = false;
  bool holdCompleteProfile = false;
  bool holdLoginA = true;
  bool failLoginB = false;
  bool rejectAuthProbe = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == '/auth/login') {
      loginCount++;
      final email = (options.data as Map<String, Object?>)['email'];
      if (email == 'a@example.com') {
        loginAStarted.complete();
        if (holdLoginA) return loginAResponse.future;
        return _json({
          'success': true,
          'data': _session('user-a', 'token-a', 'refresh-a'),
        });
      }
      if (!loginBStarted.isCompleted) loginBStarted.complete();
      if (failLoginB) return ResponseBody.fromString('', 401);
      return _json({
        'success': true,
        'data': _session('user-b', 'token-b', 'refresh-b'),
      });
    }
    if (options.path == '/auth/biometric-login') {
      return _json({
        'success': true,
        'data': {
          ..._session('bio-owner', 'bio-access', 'bio-refresh'),
          'biometricToken': 'biometric-secret',
        },
      });
    }
    if (options.path == '/auth/complete-profile' && holdCompleteProfile) {
      completeProfileStarted.complete();
      return completeProfileResponse.future;
    }
    if (options.path == '/users/me' && holdCurrentUser) {
      currentUserStarted.complete();
      return currentUserResponse.future;
    }
    if (options.path == '/users/me') {
      return _json({
        'success': true,
        'data': {'id': 'restored-user', 'email': 'restored@example.com'},
      });
    }
    if (rejectAuthProbe &&
        (options.path == '/probe' || options.path == '/after-cancel')) {
      return ResponseBody.fromString('', 401);
    }
    if (options.path == '/cart') {
      return _json({
        'success': true,
        'data': {
          'items': [],
          'totalItems': options.headers['Authorization'] == 'Bearer token-b'
              ? 2
              : 1,
          'totalPrice': 0,
        },
      });
    }
    return _json({'success': true, 'data': null});
  }

  static Map<String, Object?> _session(
    String id,
    String token,
    String refreshToken,
  ) => {
    'token': token,
    'refreshToken': refreshToken,
    'user': {'id': id, 'email': '$id@example.com'},
  };

  static ResponseBody _json(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _Biometry extends BiometryService {
  _Biometry({
    required this.enabled,
    required this.available,
    required this.authenticated,
  });

  final Future<bool> Function() enabled;
  final Future<bool> Function() available;
  final Future<bool> Function() authenticated;
  int prompts = 0;

  @override
  Future<bool> isEnabled() => enabled();

  @override
  Future<bool> isAvailable() => available();

  @override
  Future<bool> hasCredentials() async => true;

  @override
  Future<bool> authenticate({String reason = 'Autentique para continuar'}) {
    prompts++;
    return authenticated();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AuthAdapter adapter;
  late ProviderContainer container;

  Future<void> configure({
    Map<String, String> secureValues = const {},
    required _Biometry biometry,
    Map<String, Object> preferences = const {'remember_me': false},
    Future<void> Function(String token)? afterAuthenticationSideEffects,
  }) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearTokens();
    FlutterSecureStorage.setMockInitialValues(Map.of(secureValues));
    SharedPreferences.setMockInitialValues(preferences);
    await StorageService.init();
    adapter = _AuthAdapter();
    HttpClient.establishSession();
    HttpClient.instance.options.headers.remove('Authorization');
    HttpClient.instance.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(
            client: HttpClient.instance,
            afterAuthenticationSideEffects: afterAuthenticationSideEffects,
          ),
        ),
        biometryServiceProvider.overrideWithValue(biometry),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
  }

  Future<void> waitForBoot() async {
    for (var i = 0; i < 200; i++) {
      if (!container.read(isInitialAuthLoadingProvider)) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('Auth initialization did not finish');
  }

  test(
    'a late login response after logout and B login cannot replace B',
    () async {
      final biometry = _Biometry(
        enabled: () async => false,
        available: () async => false,
        authenticated: () async => false,
      );
      await configure(biometry: biometry);
      await waitForBoot();

      final loginA = container
          .read(authControllerProvider.notifier)
          .login('a@example.com', 'password');
      await adapter.loginAStarted.future;
      await container.read(authControllerProvider.notifier).logout();
      await container
          .read(authControllerProvider.notifier)
          .login('b@example.com', 'password');
      adapter.loginAResponse.complete(
        _AuthAdapter._json({
          'success': true,
          'data': _AuthAdapter._session('user-a', 'token-a', 'refresh-a'),
        }),
      );
      await loginA;

      expect(container.read(authControllerProvider).value?.id, 'user-b');
      expect(await StorageService.getToken(), 'token-b');
      expect(container.read(cartProvider).cart.totalItems, 2);
      expect(
        adapter.requests
            .where((request) => request.path == '/cart')
            .map((request) => request.headers['Authorization']),
        ['Bearer token-b'],
      );
    },
  );

  test(
    'same-account re-login replaces bearer and hydrates a fresh cart',
    () async {
      final biometry = _Biometry(
        enabled: () async => false,
        available: () async => false,
        authenticated: () async => false,
      );
      await configure(biometry: biometry);
      await waitForBoot();

      await container
          .read(authControllerProvider.notifier)
          .login('b@example.com', 'password');
      await container
          .read(authControllerProvider.notifier)
          .login('b@example.com', 'password');

      expect(container.read(authControllerProvider).value?.id, 'user-b');
      expect(await StorageService.getToken(), 'token-b');
      expect(adapter.loginCount, 2);
      expect(
        adapter.requests.where((request) => request.path == '/cart').length,
        2,
      );
      await container.read(authControllerProvider.notifier).logout();
      final logoutRequest = adapter.requests.singleWhere(
        (request) => request.path == '/auth/logout',
      );
      expect(logoutRequest.headers['Authorization'], 'Bearer token-b');
      await HttpClient.instance.get('/after-logout');
      expect(adapter.requests.last.headers['Authorization'], isNull);
    },
  );

  test(
    'stale boot user failure cannot clear the newer credential session',
    () async {
      final biometry = _Biometry(
        enabled: () async => false,
        available: () async => false,
        authenticated: () async => false,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      adapter.holdCurrentUser = true;
      await adapter.currentUserStarted.future;

      await container
          .read(authControllerProvider.notifier)
          .login('b@example.com', 'password');
      adapter.currentUserResponse.complete(ResponseBody.fromString('', 401));
      await waitForBoot();

      expect(container.read(authControllerProvider).value?.id, 'user-b');
      expect(await StorageService.getToken(), 'token-b');
    },
  );

  test('stale profile completion cannot overwrite a newer account', () async {
    final biometry = _Biometry(
      enabled: () async => false,
      available: () async => false,
      authenticated: () async => false,
    );
    await configure(biometry: biometry);
    await waitForBoot();
    await container
        .read(authControllerProvider.notifier)
        .login('b@example.com', 'password');
    adapter.holdCompleteProfile = true;
    final update = container
        .read(authControllerProvider.notifier)
        .completeProfile(username: 'stale');
    await adapter.completeProfileStarted.future;

    await container
        .read(authControllerProvider.notifier)
        .login('b@example.com', 'password');
    adapter.completeProfileResponse.complete(
      _AuthAdapter._json({
        'success': true,
        'data': {
          'user': {'id': 'user-a', 'email': 'a@example.com'},
        },
      }),
    );
    await update;

    expect(container.read(authControllerProvider).value?.id, 'user-b');
    expect(await StorageService.getToken(), 'token-b');
  });

  test(
    'cold start suspends cached bearer while biometric consent is unresolved',
    () async {
      final consent = Completer<bool>();
      final biometry = _Biometry(
        enabled: () => consent.future,
        available: () async => false,
        authenticated: () async => false,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      HttpClient.instance.options.headers['Authorization'] = 'Bearer cached';
      await Future<void>.delayed(const Duration(milliseconds: 20));

      adapter.rejectAuthProbe = true;
      await expectLater(
        HttpClient.instance.get('/probe'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests.last.headers['Authorization'], isNull);
      expect(
        adapter.requests.where((request) => request.path == '/auth/refresh'),
        isEmpty,
      );
      expect(
        adapter.requests.where((request) => request.path == '/users/me'),
        isEmpty,
      );
      consent.complete(true);
      await waitForBoot();
      expect(await StorageService.getToken(), isNull);
    },
  );

  test('an installed A token and metadata roll back when B succeeds', () async {
    final biometry = _Biometry(
      enabled: () async => false,
      available: () async => false,
      authenticated: () async => false,
    );
    final hookEntered = Completer<void>();
    final releaseHook = Completer<void>();
    await configure(
      secureValues: const {'saved_email': 'prior@example.com'},
      preferences: const {'remember_me': true},
      biometry: biometry,
      afterAuthenticationSideEffects: (token) async {
        if (token == 'token-a') {
          hookEntered.complete();
          await releaseHook.future;
        }
      },
    );
    await waitForBoot();
    adapter.holdLoginA = false;
    final loginA = container
        .read(authControllerProvider.notifier)
        .login('a@example.com', 'password');
    await hookEntered.future;
    expect(await StorageService.getEmail(), 'user-a@example.com');
    expect(await StorageService.getRememberMe(), isFalse);
    final loginB = container
        .read(authControllerProvider.notifier)
        .login('b@example.com', 'password', rememberMe: true);
    await adapter.loginBStarted.future;
    releaseHook.complete();
    await Future.wait([loginA, loginB]);

    expect(container.read(authControllerProvider).value?.id, 'user-b');
    expect(await StorageService.getToken(), 'token-b');
    expect(await StorageService.getEmail(), 'user-b@example.com');
    expect(await StorageService.getRememberMe(), isTrue);
  });

  test('an installed A token and metadata roll back when B fails', () async {
    final biometry = _Biometry(
      enabled: () async => false,
      available: () async => false,
      authenticated: () async => false,
    );
    final hookEntered = Completer<void>();
    final releaseHook = Completer<void>();
    await configure(
      secureValues: const {'saved_email': 'prior@example.com'},
      preferences: const {'remember_me': true},
      biometry: biometry,
      afterAuthenticationSideEffects: (token) async {
        if (token == 'token-a') {
          hookEntered.complete();
          await releaseHook.future;
        }
      },
    );
    await waitForBoot();
    adapter.holdLoginA = false;
    adapter.failLoginB = true;
    final loginA = container
        .read(authControllerProvider.notifier)
        .login('a@example.com', 'password');
    await hookEntered.future;
    expect(await StorageService.getEmail(), 'user-a@example.com');
    expect(await StorageService.getRememberMe(), isFalse);
    final loginB = container
        .read(authControllerProvider.notifier)
        .login('b@example.com', 'password');
    await adapter.loginBStarted.future;
    releaseHook.complete();
    await Future.wait([loginA, loginB]);

    expect(container.read(authControllerProvider).hasError, isTrue);
    expect(await StorageService.getToken(), isNull);
    expect(await StorageService.getEmail(), 'prior@example.com');
    expect(await StorageService.getRememberMe(), isTrue);
  });

  test(
    'opted-in cold start cancellation never restores remembered bearer',
    () async {
      final biometry = _Biometry(
        enabled: () async => true,
        available: () async => true,
        authenticated: () async => false,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
          'biometric_token': 'biometric-secret',
          'biometry_owner_id': 'bio-owner',
          'biometry_enabled': 'true',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      await waitForBoot();

      expect(container.read(authControllerProvider).value, isNull);
      expect(
        adapter.requests.where((request) => request.path == '/users/me'),
        isEmpty,
      );
      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getBiometricToken(), 'biometric-secret');
      expect(await BiometryService().isEnabled(), isTrue);
      expect(biometry.prompts, 1);
      adapter.rejectAuthProbe = true;
      await expectLater(
        HttpClient.instance.get('/after-cancel'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.last.headers['Authorization'], isNull);
      expect(
        adapter.requests.where((request) => request.path == '/auth/refresh'),
        isEmpty,
      );
    },
  );

  test(
    'enabled but unavailable biometrics do not restore remembered session',
    () async {
      final biometry = _Biometry(
        enabled: () async => true,
        available: () async => false,
        authenticated: () async => false,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
          'biometric_token': 'biometric-secret',
          'biometry_owner_id': 'bio-owner',
          'biometry_enabled': 'true',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      await waitForBoot();

      expect(container.read(authControllerProvider).value, isNull);
      expect(
        adapter.requests.where((request) => request.path == '/users/me'),
        isEmpty,
      );
      expect(await StorageService.getToken(), isNull);
      expect(await StorageService.getBiometricToken(), 'biometric-secret');
      expect(biometry.prompts, 0);
    },
  );

  test(
    'disabled biometrics restore remembered session without prompting',
    () async {
      final biometry = _Biometry(
        enabled: () async => false,
        available: () async => true,
        authenticated: () async => true,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      await waitForBoot();

      expect(container.read(authControllerProvider).value?.id, 'restored-user');
      expect(
        adapter.requests
            .where((request) => request.path == '/users/me')
            .single
            .headers['Authorization'],
        'Bearer remembered-access',
      );
      expect(biometry.prompts, 0);
    },
  );

  test('non-remembered boot clears bearer and does not prompt', () async {
    final biometry = _Biometry(
      enabled: () async => true,
      available: () async => true,
      authenticated: () async => true,
    );
    await configure(
      secureValues: const {
        'auth_token': 'remembered-access',
        'refresh_token': 'remembered-refresh',
        'biometric_token': 'biometric-secret',
      },
      biometry: biometry,
    );
    await waitForBoot();

    expect(container.read(authControllerProvider).value, isNull);
    expect(await StorageService.getToken(), isNull);
    expect(
      adapter.requests.where((request) => request.path == '/users/me'),
      isEmpty,
    );
    expect(biometry.prompts, 0);
  });

  test(
    'biometric owner is checked before a successful response installs tokens',
    () async {
      final biometry = _Biometry(
        enabled: () async => true,
        available: () async => true,
        authenticated: () async => true,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
          'biometric_token': 'biometric-secret',
          'biometry_owner_id': 'expected-owner',
          'biometry_enabled': 'true',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      await waitForBoot();

      expect(container.read(authControllerProvider).value, isNull);
      expect(await StorageService.getToken(), isNull);
      expect(
        adapter.requests.where((request) => request.path == '/users/me'),
        isEmpty,
      );
      expect(
        adapter.requests
            .singleWhere((request) => request.path == '/auth/biometric-login')
            .headers['Authorization'],
        isNull,
      );
    },
  );

  test(
    'opted-in cold start establishes only the matching biometric account',
    () async {
      final biometry = _Biometry(
        enabled: () async => true,
        available: () async => true,
        authenticated: () async => true,
      );
      await configure(
        secureValues: const {
          'auth_token': 'remembered-access',
          'refresh_token': 'remembered-refresh',
          'biometric_token': 'biometric-secret',
          'biometry_owner_id': 'bio-owner',
          'biometry_enabled': 'true',
        },
        preferences: const {'remember_me': true},
        biometry: biometry,
      );
      await waitForBoot();

      expect(container.read(authControllerProvider).value?.id, 'bio-owner');
      expect(await StorageService.getToken(), 'bio-access');
      expect(
        adapter.requests
            .singleWhere((request) => request.path == '/auth/biometric-login')
            .headers['Authorization'],
        isNull,
      );
      expect(
        adapter.requests.where((request) => request.path == '/users/me'),
        isEmpty,
      );
      expect(biometry.prompts, 1);
    },
  );
}
