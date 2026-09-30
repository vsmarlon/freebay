import 'package:dio/dio.dart';
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

  AuthRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, void>> logout() async {
    String? accessToken;
    String? refreshToken;
    String? biometricToken;
    HttpClient.suspendRefresh();
    try {
      accessToken = await StorageService.getToken();
      refreshToken = await StorageService.getRefreshToken();
      biometricToken = await StorageService.getBiometricToken();
      final installationId = await StorageService.getPushInstallationId();

      final result = await requestEither<void>(
        () => client.post(
          '/auth/logout',
          data: {
            'refreshToken': ?refreshToken,
            'biometricToken': ?biometricToken,
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
    required Future<Response> Function() request,
    required String debugLabel,
    required Failure missingDataFailure,
    Future<void> Function(dynamic data)? afterTokens,
  }) {
    return requestEither<UserEntity>(
      request,
      debugLabel: debugLabel,
      decoder: (response) async {
        final data = response.data?['data'];
        if (data == null) return Left(missingDataFailure);
        await AuthSessionCoordinator.installTokensAndEstablish(
          () =>
              StorageService.saveTokenPair(data['token'], data['refreshToken']),
        );
        await afterTokens?.call(data);
        final user = UserEntity.fromJson(data['user']);
        if (user.email != null) await StorageService.saveEmail(user.email!);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    final result = await _authenticate(
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
    String username,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    final result = await _authenticate(
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
    );
    if (result.isRight) await StorageService.saveRememberMe(false);
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
    String biometricToken,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    return _authenticate(
      request: () => client.post(
        '/auth/biometric-login',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH biometric',
      missingDataFailure: const InvalidCredentialsFailure(),
      afterTokens: (data) async {
        await StorageService.saveBiometricToken(data['biometricToken']);
      },
    );
  }

  Future<Either<Failure, void>> revokeBiometricToken() async {
    final biometricToken = await StorageService.getBiometricToken();
    if (biometricToken == null) return const Right(null);
    return requestEither<void>(
      () => client.patch(
        '/auth/biometric-token/revoke',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH revoke biometric',
      decoder: (_) => const Right(null),
    );
  }

  Future<Either<Failure, String>> enrollBiometricToken() => requestEither(
    () => client.post('/auth/biometric-token/enroll'),
    decoder: (response) =>
        Right(response.data['data']['biometricToken'] as String),
    debugLabel: 'AUTH enroll biometric',
  );

  Future<Either<Failure, UserEntity>> googleAuth(String idToken) async {
    AuthSessionCoordinator.beginAuthentication();
    return _authenticate(
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
