import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class AuthRepository extends BaseHttpRepository {
  AuthRepository({super.client});

  Future<Either<Failure, void>> logout() async {
    String? accessToken;
    String? refreshToken;
    String? biometricToken;
    HttpClient.suspendRefresh();
    try {
      accessToken = await StorageService.getToken();
      refreshToken = await StorageService.getRefreshToken();
      biometricToken = await StorageService.getBiometricToken();

      final result = await safeVoid(
        () => client.post(
          '/auth/logout',
          data: {
            'refreshToken': ?refreshToken,
            'biometricToken': ?biometricToken,
          },
          options: Options(
            extra: {
              HttpClient.preserveCapturedAuthKey: true,
              HttpClient.capturedAuthTokenKey: accessToken,
              HttpClient.disableRefreshKey: true,
            },
          ),
        ),
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

  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return const Right(false);
      final rememberMe = await StorageService.getRememberMe();
      return Right(rememberMe);
    } catch (_) {
      return const Left(CacheFailure('Erro ao ler token de acesso.'));
    }
  }

  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    return safeCall<UserEntity>(
      () => client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
      debugLabel: 'AUTH login',
      onSuccess: (response) async {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(InvalidCredentialsFailure());
        }
        await AuthSessionCoordinator.installTokensAndEstablish(
          () =>
              StorageService.saveTokenPair(data['token'], data['refreshToken']),
        );
        await StorageService.saveEmail(email);
        await StorageService.saveRememberMe(rememberMe);
        final user = UserEntity.fromJson(data['user']);
        if (user.email != null) await StorageService.saveEmail(user.email!);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, UserEntity>> getCurrentUser() => safeGet<UserEntity>(
    '/users/me',
    extractKey: 'data',
    fromJson: UserEntity.fromJson,
  );

  Future<Either<Failure, UserEntity>> register(
    String email,
    String password,
    String displayName,
    String username,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    final result = await safeCall<UserEntity>(
      () => client.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
          'username': username,
        },
      ),
      debugLabel: 'AUTH register',
      onSuccess: (response) async {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(ServerFailure('Falha ao registrar usuário.'));
        }
        await AuthSessionCoordinator.installTokensAndEstablish(
          () =>
              StorageService.saveTokenPair(data['token'], data['refreshToken']),
        );
        final user = UserEntity.fromJson(data['user']);
        if (user.email != null) await StorageService.saveEmail(user.email!);
        return Right(user);
      },
    );
    if (result.isRight) await StorageService.saveRememberMe(false);
    return result;
  }

  Future<Either<Failure, bool>> checkUsernameAvailable(String username) =>
      safeGet<bool>(
        '/auth/username-available',
        queryParameters: {'u': username},
        extractKey: 'data.available',
        customMapper: (d) => d == true,
      );

  Future<Either<Failure, void>> requestPasswordRecovery(String email) =>
      safeVoid(
        () => client.post('/auth/forgot-password', data: {'email': email}),
      );

  Future<Either<Failure, bool>> verifyPasswordRecoveryCode(
    String email,
    String code,
  ) => safePost<bool>(
    '/auth/verify-reset-code',
    data: {'email': email, 'code': code},
    customMapper: (_) => true,
  );

  Future<Either<Failure, void>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) => safeVoid(
    () => client.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    ),
  );

  Future<Either<Failure, UserEntity>> biometricLogin(
    String biometricToken,
  ) async {
    AuthSessionCoordinator.beginAuthentication();
    return safeCall<UserEntity>(
      () => client.post(
        '/auth/biometric-login',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH biometric',
      onSuccess: (response) async {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(InvalidCredentialsFailure());
        }
        await AuthSessionCoordinator.installTokensAndEstablish(
          () =>
              StorageService.saveTokenPair(data['token'], data['refreshToken']),
        );
        await StorageService.saveBiometricToken(data['biometricToken']);
        final user = UserEntity.fromJson(data['user']);
        if (user.email != null) await StorageService.saveEmail(user.email!);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, void>> revokeBiometricToken() async {
    final biometricToken = await StorageService.getBiometricToken();
    if (biometricToken == null) return const Right(null);
    return safeVoid(
      () => client.patch(
        '/auth/biometric-token/revoke',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH revoke biometric',
    );
  }

  Future<Either<Failure, String>> enrollBiometricToken() => safePost<String>(
    '/auth/biometric-token/enroll',
    customMapper: (data) => data['biometricToken'] as String,
    debugLabel: 'AUTH enroll biometric',
  );

  Future<Either<Failure, UserEntity>> googleAuth(String idToken) async {
    AuthSessionCoordinator.beginAuthentication();
    return safeCall<UserEntity>(
      () => client.post('/auth/google', data: {'idToken': idToken}),
      debugLabel: 'AUTH google',
      onSuccess: (response) async {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(ServerFailure('Falha ao autenticar com Google.'));
        }
        await AuthSessionCoordinator.installTokensAndEstablish(
          () =>
              StorageService.saveTokenPair(data['token'], data['refreshToken']),
        );
        await StorageService.saveRememberMe(true);
        final user = UserEntity.fromJson(data['user']);
        if (user.email != null) await StorageService.saveEmail(user.email!);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, UserEntity>> completeProfile({
    required String username,
    String? displayName,
    String? city,
    String? state,
  }) async {
    return safeCall<UserEntity>(
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
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null) {
          return const Left(ServerFailure('Falha ao completar perfil.'));
        }
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }
}
