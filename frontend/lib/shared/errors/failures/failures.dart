import 'package:dio/dio.dart';
import 'package:freebay/shared/errors/error_messages.dart';

abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      runtimeType == other.runtimeType &&
      message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro ao se comunicar com o servidor.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'O servidor demorou para responder. Tente novamente.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao ler dados locais.']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Email ou senha incorretos.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Sessão expirada. Faça login novamente.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Dados inválidos.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Ocorreu um erro inesperado. Tente novamente.',
  ]);
}

/// Biometric prompt was cancelled by the user or the device.
/// Credentials are NOT cleared — the user can retry.
class BiometryCancelledFailure extends Failure {
  const BiometryCancelledFailure([
    super.message = 'Autenticação biométrica cancelada.',
  ]);
}

/// Converts DioException to user-friendly Failure
Failure mapDioExceptionToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();

    case DioExceptionType.connectionError:
      return const NetworkFailure();

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      final mapped = switch (responseData) {
        {'error': {'code': final String code}} => messageForCode(code),
        _ => null,
      };

      switch (statusCode) {
        case 400:
          return ValidationFailure(mapped ?? 'Dados inválidos.');
        case 401:
          return UnauthorizedFailure(
            mapped ?? 'Sessão expirada. Faça login novamente.',
          );
        case 403:
          return ServerFailure(
            mapped ?? 'Você não tem permissão para esta ação.',
          );
        case 404:
          return NotFoundFailure(mapped ?? 'Recurso não encontrado.');
        case 409:
          return ServerFailure(mapped ?? 'Não foi possível concluir.');
        case 422:
          return ValidationFailure(mapped ?? 'Dados inválidos.');
        case 429:
          return const ServerFailure('Muitas tentativas. Aguarde um momento.');
        case 500:
        case 502:
        case 503:
          return const ServerFailure(
            'Servidor indisponível. Tente novamente mais tarde.',
          );
        default:
          return ServerFailure(
            mapped ?? 'Erro ao se comunicar com o servidor.',
          );
      }

    case DioExceptionType.cancel:
      return const UnknownFailure('Requisição cancelada.');

    case DioExceptionType.badCertificate:
      return const ServerFailure('Erro de segurança na conexão.');

    case DioExceptionType.unknown:
      if (e.error.toString().contains('SocketException') ||
          e.error.toString().contains('Connection refused')) {
        return const NetworkFailure('Não foi possível conectar ao servidor.');
      }
      return const UnknownFailure();
  }
}
