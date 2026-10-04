import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

typedef UsernameAvailability = ({bool available, List<String> suggestions});

class AuthRepository {
  final Dio client;
  @visibleForTesting
  final Future<void> Function(String token)? afterAuthenticationSideEffects;

  AuthRepository({Dio? client, this.afterAuthenticationSideEffects})
    : client = client ?? HttpClient.instance;

  Future<Either<Failure, void>> logout() async {
    String? accessToken;
    String? refreshToken;
    HttpClient.suspendRefresh();
    try {
      accessToken = await StorageService.getToken();
      refreshToken = await StorageService.getRefreshToken();
      final installationId = await StorageService.getPushInstallationId();

      final result = await requestEither<void>(
        () => client.post(
          '/auth/logout',
          data: {
            'refreshToken': ?refreshToken,
            'installationId': installationId,
          },
          options: Options(
            extra: {
              HttpClient.preserveCapturedAuthKey: true,
              HttpClient.capturedAuthTokenKey: accessToken,
              HttpClient.disableRefreshKey: true,
            },
          ),
        ),
        decoder: (_) => const Right(null),
        debugLabel: 'AUTH logout',
      );

      return result;
    } catch (_) {
      return const Left(CacheFailure('Erro ao limpar tokens de acesso.'));
    } finally {
      try {
        await BiometryService().clearState();
      } catch (_) {}
      try {
        await StorageService.clearTokens();
      } catch (_) {}
    }
  }

  Future<Either<Failure, UserEntity>> _authenticate({
    required int attempt,
    required Future<Response> Function() request,
    required String debugLabel,
    required Failure missingDataFailure,
    String? expectedUserId,
    Future<void> Function()? onUserMismatch,
    Future<void> Function(dynamic data)? afterTokens,
  }) {
    return requestEither<UserEntity>(
      request,
      debugLabel: debugLabel,
      decoder: (response) async {
        final data = response.data?['data'];
        if (data == null) return Left(missingDataFailure);
        if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) {
          return const Left(CacheFailure('Authentication attempt superseded.'));
        }
        final user = UserEntity.fromJson(data['user']);
        if (expectedUserId != null && user.id != expectedUserId) {
          await onUserMismatch?.call();
          return const Left(
            CacheFailure('A biometria pertence a outra conta.'),
          );
        }
        final installed =
            await AuthSessionCoordinator.installTokensAndEstablish(
              attempt: attempt,
              token: data['token'] as String,
              refreshToken: data['refreshToken'] as String?,
              afterAuthenticationSideEffects: () =>
                  afterAuthenticationSideEffects?.call(
                    data['token'] as String,
                  ) ??
                  Future<void>.value(),
              captureRollback: () async {
                final email = await StorageService.getEmail();
                final rememberMe = await StorageService.getRememberMe();
                final biometricOwner = await StorageService.getBiometricOwner();
                return () => StorageService.restoreAuthenticationMetadata(
                  email: email,
                  rememberMe: rememberMe,
                  biometricOwner: biometricOwner,
                );
              },
              afterInstall: () async {
                await afterTokens?.call(data);
                if (user.email != null) {
                  await StorageService.saveEmail(user.email!);
                }
              },
            );
        if (!installed) {
          return const Left(CacheFailure('Authentication attempt superseded.'));
        }
        return Right(user);
      },
    );
  }

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
    bool rememberMe, {
    required int authenticationAttempt,
  }) async {
    final result = await _authenticate(
      attempt: authenticationAttempt,
      request: () => client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
      debugLabel: 'AUTH login',
      missingDataFailure: const InvalidCredentialsFailure(),
      afterTokens: (_) async {
        await StorageService.saveEmail(email);
        await StorageService.saveRememberMe(rememberMe);
      },
    );
    return result;
  }

  Future<Either<Failure, UserEntity>> getCurrentUser() => requestEither(
    () => client.get('/users/me'),
    decoder: (response) => Right(UserEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, UserEntity>> register(
    String email,
    String password,
    String displayName,
    String username, {
    required int authenticationAttempt,
  }) async {
    final result = await _authenticate(
      attempt: authenticationAttempt,
      request: () => client.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
          'username': username,
        },
      ),
      debugLabel: 'AUTH register',
      missingDataFailure: const ServerFailure('Falha ao registrar usuário.'),
      afterTokens: (_) => StorageService.saveRememberMe(false),
    );
    return result;
  }

  Future<Either<Failure, UsernameAvailability>> checkUsernameAvailable(
    String username,
  ) => requestEither(
    () => client.get(
      '/auth/username-available',
      queryParameters: {'u': username},
    ),
    decoder: (response) => Right((
      available: response.data['data']['available'] == true,
      suggestions: List<String>.from(
        response.data['data']['suggestions'] as List? ?? const [],
      ),
    )),
  );

  Future<Either<Failure, void>> requestPasswordRecovery(String email) =>
      requestEither<void>(
        () => client.post('/auth/forgot-password', data: {'email': email}),
        decoder: (_) => const Right(null),
      );

  Future<Either<Failure, bool>> verifyPasswordRecoveryCode(
    String email,
    String code,
  ) => requestEither(
    () => client.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    ),
    decoder: (_) => const Right(true),
  );

  Future<Either<Failure, void>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) => requestEither<void>(
    () => client.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    ),
    decoder: (_) => const Right(null),
  );

  Future<Either<Failure, UserEntity>> biometricLogin(
    String biometricToken, {
    required String challengeId,
    required String signature,
    required String expectedUserId,
    required int authenticationAttempt,
  }) async {
    return _authenticate(
      attempt: authenticationAttempt,
      expectedUserId: expectedUserId,
      onUserMismatch: () => AuthSessionCoordinator.serialize(() async {
        if (AuthSessionCoordinator.isCurrentAttempt(authenticationAttempt)) {
          await BiometryService().clearState();
        }
      }),
      request: () => client.post(
        '/auth/biometric-login',
        data: {
          'biometricToken': biometricToken,
          'challengeId': challengeId,
          'signature': signature,
        },
      ),
      debugLabel: 'AUTH biometric',
      missingDataFailure: const InvalidCredentialsFailure(),
      afterTokens: (data) async {
        await StorageService.saveBiometricToken(data['biometricToken']);
      },
    );
  }

  Future<Either<Failure, ({String challengeId, String challenge})>>
  createBiometricChallenge(
    String biometricToken, {
    required String purpose,
    String? stepUpPurpose,
    String? resourceId,
  }) => requestEither(
    () => client.post(
      '/auth/biometric-challenge',
      data: {
        'biometricToken': biometricToken,
        'purpose': purpose,
        if (stepUpPurpose != null) 'stepUpPurpose': stepUpPurpose,
        if (resourceId != null) 'resourceId': resourceId,
      },
    ),
    decoder: (response) {
      final data = response.data?['data'];
      if (data is! Map<String, dynamic> ||
          data['challengeId'] is! String ||
          data['challenge'] is! String) {
        return const Left(ServerFailure('Invalid biometric challenge.'));
      }
      return Right((
        challengeId: data['challengeId'] as String,
        challenge: data['challenge'] as String,
      ));
    },
    debugLabel: 'AUTH biometric challenge',
  );

  Future<Either<Failure, ({String challengeId, String challenge})>>
  createBiometricLoginChallenge(String biometricToken) =>
      createBiometricChallenge(biometricToken, purpose: 'login');

  Future<Either<Failure, String>> createStepUp({
    required String purpose,
    String? resourceId,
    required Map<String, Object?> proof,
  }) => requestEither(
    () => client.post(
      '/auth/step-up',
      data: {
        'purpose': purpose,
        if (resourceId != null) 'resourceId': resourceId,
        'proof': proof,
      },
    ),
    decoder: (response) {
      final token = response.data?['data']?['stepUpToken'];
      return token is String && token.isNotEmpty
          ? Right(token)
          : const Left(ServerFailure('Invalid step-up response.'));
    },
    debugLabel: 'AUTH step-up',
  );

  Future<Either<Failure, void>> revokeBiometricToken() async {
    final biometricToken = await StorageService.getBiometricToken();
    if (biometricToken == null)
      return const Left(
        CacheFailure('Biometric revocation could not be confirmed.'),
      );
    return requestEither<void>(
      () => client.patch(
        '/auth/biometric-token/revoke',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH revoke biometric',
      decoder: (_) => const Right(null),
    );
  }

  Future<Either<Failure, String>> enrollBiometricToken({
    required String stepUpToken,
    required String publicKey,
  }) => requestEither(
    () => client.post(
      '/auth/biometric-token/enroll',
      data: {'stepUpToken': stepUpToken, 'publicKey': publicKey},
    ),
    decoder: (response) =>
        Right(response.data['data']['biometricToken'] as String),
    debugLabel: 'AUTH enroll biometric',
  );

  Future<Either<Failure, UserEntity>> googleAuth(
    String idToken, {
    required int authenticationAttempt,
  }) async {
    return _authenticate(
      attempt: authenticationAttempt,
      request: () => client.post('/auth/google', data: {'idToken': idToken}),
      debugLabel: 'AUTH google',
      missingDataFailure: const ServerFailure(
        'Falha ao autenticar com Google.',
      ),
      afterTokens: (_) async {
        await StorageService.saveRememberMe(true);
      },
    );
  }

  Future<Either<Failure, UserEntity>> appleAuth({
    required String identityToken,
    required String authorizationCode,
    required String rawNonce,
    required int authenticationAttempt,
    String? fullName,
  }) async {
    return _authenticate(
      attempt: authenticationAttempt,
      request: () => client.post(
        '/auth/apple',
        data: {
          'identityToken': identityToken,
          'authorizationCode': authorizationCode,
          'rawNonce': rawNonce,
          'fullName': ?fullName,
        },
      ),
      debugLabel: 'AUTH apple',
      missingDataFailure: const ServerFailure(),
      afterTokens: (_) async {
        await StorageService.saveRememberMe(true);
      },
    );
  }

  Future<Either<Failure, UserEntity>> completeProfile({
    required String username,
    String? displayName,
    String? city,
    String? state,
  }) async {
    return requestEither<UserEntity>(
      () => client.post(
        '/auth/complete-profile',
        data: {
          'username': username,
          'displayName': displayName,
          'city': city,
          'state': state,
        },
      ),
      debugLabel: 'AUTH complete-profile',
      decoder: (response) {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(ServerFailure('Falha ao completar perfil.'));
        }
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }
}
