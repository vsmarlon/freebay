import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class AuthRepository extends BaseHttpRepository implements IAuthRepository {
  AuthRepository({super.client});

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null) {
        await safeVoid(
          () => client.delete(
            '/auth/logout',
            data: {'refreshToken': refreshToken},
          ),
          debugLabel: 'AUTH logout',
        );
      }
      await StorageService.clearTokens();
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure('Erro ao limpar tokens de acesso.'));
    }
  }

  @override
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

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    return safeCall<UserEntity>(
      () => client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
      debugLabel: 'AUTH login',
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null) return const Left(InvalidCredentialsFailure());
        StorageService.saveToken(data['token']);
        StorageService.saveRefreshToken(data['refreshToken']);
        if (data['biometricToken'] != null) {
          StorageService.saveBiometricToken(data['biometricToken']);
        }
        StorageService.saveRememberMe(rememberMe);
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() => safeGet<UserEntity>(
    '/users/me',
    extractKey: 'data',
    fromJson: UserEntity.fromJson,
  );

  @override
  Future<Either<Failure, UserEntity>> register(
    String email,
    String password,
    String displayName,
    String username,
  ) async {
    return safeCall<UserEntity>(
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
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null)
          return const Left(ServerFailure('Falha ao registrar usuário.'));
        StorageService.saveToken(data['token']);
        if (data['refreshToken'] != null) {
          StorageService.saveRefreshToken(data['refreshToken']);
        }
        if (data['biometricToken'] != null) {
          StorageService.saveBiometricToken(data['biometricToken']);
        }
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }

  @override
  Future<Either<Failure, bool>> checkUsernameAvailable(String username) =>
      safeGet<bool>(
        '/auth/username-available',
        queryParameters: {'u': username},
        extractKey: 'data.available',
        customMapper: (d) => d == true,
      );

  @override
  Future<Either<Failure, void>> requestPasswordRecovery(String email) =>
      safeVoid(
        () => client.post('/auth/forgot-password', data: {'email': email}),
      );

  @override
  Future<Either<Failure, bool>> verifyPasswordRecoveryCode(
    String email,
    String code,
  ) => safePost<bool>(
    '/auth/verify-reset-code',
    data: {'email': email, 'code': code},
    customMapper: (_) => true,
  );

  @override
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

  @override
  Future<Either<Failure, UserEntity>> biometricLogin(
    String biometricToken,
  ) async {
    return safeCall<UserEntity>(
      () => client.post(
        '/auth/biometric-login',
        data: {'biometricToken': biometricToken},
      ),
      debugLabel: 'AUTH biometric',
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null) return const Left(InvalidCredentialsFailure());
        StorageService.saveToken(data['token']);
        StorageService.saveRefreshToken(data['refreshToken']);
        if (data['biometricToken'] != null) {
          StorageService.saveBiometricToken(data['biometricToken']);
        }
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }

  @override
  Future<Either<Failure, void>> revokeBiometricToken() =>
      safeVoid(() => client.delete('/auth/biometric-token'));

  @override
  Future<Either<Failure, UserEntity>> googleAuth(String idToken) async {
    return safeCall<UserEntity>(
      () => client.post('/auth/google', data: {'idToken': idToken}),
      debugLabel: 'AUTH google',
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null)
          return const Left(ServerFailure('Falha ao autenticar com Google.'));
        StorageService.saveToken(data['token']);
        StorageService.saveRefreshToken(data['refreshToken']);
        if (data['biometricToken'] != null) {
          StorageService.saveBiometricToken(data['biometricToken']);
        }
        StorageService.saveRememberMe(true);
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }

  @override
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
          'displayName': ?displayName,
          'city': ?city,
          'state': ?state,
        },
      ),
      debugLabel: 'AUTH complete-profile',
      onSuccess: (response) {
        final data = response.data?['data'];
        if (data == null)
          return const Left(ServerFailure('Falha ao completar perfil.'));
        return Right(UserEntity.fromJson(data['user']));
      },
    );
  }
}
