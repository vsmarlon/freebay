import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../entities/user_entity.dart';

class AuthRepository implements IAuthRepository {
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData != null && responseData is Map) {
        final errorObj = responseData['error'];
        if (errorObj != null && errorObj is Map) {
          final message = errorObj['message'];
          if (message != null) return message.toString();
          final code = errorObj['code'];
          if (code != null) {
            return _mapErrorCode(code.toString());
          }
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tempo de conexão esgotado. Tente novamente.';
        case DioExceptionType.connectionError:
          return 'Sem conexão com o servidor. Verifique sua internet.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) return 'E-mail ou senha incorretos.';
          if (statusCode == 400) return 'Dados inválidos. Verifique os campos.';
          if (statusCode == 409) return 'E-mail já cadastrado.';
          if (statusCode != null && statusCode >= 500) {
            return 'Erro no servidor. Tente novamente mais tarde.';
          }
        default:
          break;
      }
    }
    return 'Erro ao fazer login. Tente novamente.';
  }

  String _mapErrorCode(String code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'E-mail ou senha incorretos.';
      case 'EMAIL_ALREADY_EXISTS':
        return 'E-mail já cadastrado.';
      case 'VALIDATION_ERROR':
        return 'Dados inválidos. Verifique os campos.';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(
      String email, String password, bool rememberMe) async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

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
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final response = await HttpClient.instance.get('/users/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return Right(UserEntity.fromJson(data));
      } else {
        return const Left(UnauthorizedFailure('Sessão expirada'));
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure('Sessão expirada'));
      }
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(
      String email, String password, String displayName) async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'];
        await StorageService.saveToken(data['token']);
        if (data['refreshToken'] != null) {
          await StorageService.saveRefreshToken(data['refreshToken']);
        }
        await StorageService.saveIsGuest(false);

        return Right(UserEntity.fromJson(data['user']));
      } else {
        return Left(
            ServerFailure(_extractErrorMessage('Falha ao registrar usuário.')));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginAsGuest() async {
    try {
      final response = await HttpClient.instance.post(
        '/auth/guest',
        options: Options(headers: {'Content-Type': 'text/plain'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        await StorageService.saveToken(data['token']);
        await StorageService.saveIsGuest(true);

        return Right(UserEntity.fromJson(data['user']));
      } else {
        return Left(ServerFailure(
            _extractErrorMessage('Falha ao entrar como convidado.')));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
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
}
