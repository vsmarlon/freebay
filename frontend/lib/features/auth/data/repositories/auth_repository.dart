import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class AuthRepository implements IAuthRepository {
  @override
  Future<Either<Failure, UserEntity>> loginAsGuest() async {
    try {
      if (kDebugMode) {
        debugPrint('[AUTH] Iniciando login como guest...');
      }

      final response = await HttpClient.instance.post('/auth/guest');

      if (kDebugMode) {
        debugPrint('[AUTH] Response status: ${response.statusCode}');
        debugPrint('[AUTH] Response data: ${response.data}');
        debugPrint('[AUTH] Response data type: ${response.data.runtimeType}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];

        if (kDebugMode) {
          debugPrint('[AUTH] data field: $data');
          debugPrint('[AUTH] data type: ${data.runtimeType}');
        }

        await StorageService.saveToken(data['token']);
        await StorageService.saveIsGuest(true);

        if (kDebugMode) {
          debugPrint('[AUTH] Token salvo com sucesso');
        }

        return Right(UserEntity.fromJson(data['user']));
      } else {
        return const Left(ServerFailure('Falha ao entrar como convidado.'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] DioException: ${e.type} - ${e.message}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AUTH] ERRO: $e');
        debugPrint('[AUTH] STACK: $stackTrace');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final rememberMe = await StorageService.getRememberMe();
      await StorageService.clearTokens();
      await StorageService.saveRememberMe(rememberMe);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Erro ao limpar tokens de acesso.'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return const Right(false);
      }
      final rememberMe = await StorageService.getRememberMe();
      return Right(rememberMe);
    } catch (e) {
      return const Left(CacheFailure('Erro ao ler token de acesso.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(
      String email, String password, bool rememberMe) async {
    try {
      if (kDebugMode) {
        debugPrint('[AUTH] Iniciando login...');
      }

      final response = await HttpClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (kDebugMode) {
        debugPrint('[AUTH] Response status: ${response.statusCode}');
        debugPrint('[AUTH] Response data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        await StorageService.saveToken(data['token']);
        await StorageService.saveRefreshToken(data['refreshToken']);
        await StorageService.saveRememberMe(rememberMe);
        await StorageService.saveIsGuest(false);
        return Right(UserEntity.fromJson(data['user']));
      } else {
        return const Left(InvalidCredentialsFailure());
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] DioException login: ${e.type} - ${e.message}');
      }
      // Special handling for 401 on login = invalid credentials
      if (e.response?.statusCode == 401) {
        return const Left(InvalidCredentialsFailure());
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AUTH] ERRO login: $e');
        debugPrint('[AUTH] STACK: $stackTrace');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      if (kDebugMode) {
        debugPrint('[AUTH] Buscando usuário atual...');
      }

      final response = await HttpClient.instance.get('/users/me');

      if (kDebugMode) {
        debugPrint('[AUTH] Response status: ${response.statusCode}');
        debugPrint('[AUTH] Response data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return Right(UserEntity.fromJson(data));
      } else {
        return const Left(UnauthorizedFailure());
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] DioException getCurrentUser: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AUTH] ERRO getCurrentUser: $e');
        debugPrint('[AUTH] STACK: $stackTrace');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
      String email, String password, String displayName) async {
    try {
      if (kDebugMode) {
        debugPrint('[AUTH] Iniciando registro...');
      }

      final response = await HttpClient.instance.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName
        },
      );

      if (kDebugMode) {
        debugPrint('[AUTH] Response status: ${response.statusCode}');
        debugPrint('[AUTH] Response data: ${response.data}');
      }

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'];
        await StorageService.saveToken(data['token']);
        if (data['refreshToken'] != null) {
          await StorageService.saveRefreshToken(data['refreshToken']);
        }
        await StorageService.saveIsGuest(false);
        return Right(UserEntity.fromJson(data['user']));
      } else {
        return const Left(ServerFailure('Falha ao registrar usuário.'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AUTH] DioException register: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AUTH] ERRO register: $e');
        debugPrint('[AUTH] STACK: $stackTrace');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordRecovery(String email) async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      return const Left(ServerFailure('Falha ao solicitar recuperação de senha.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPasswordRecoveryCode(String email, String code) async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200) {
        return const Right(true);
      }

      return const Left(ServerFailure('Falha ao verificar o código.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      return const Left(ServerFailure('Falha ao redefinir a senha.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }
}
