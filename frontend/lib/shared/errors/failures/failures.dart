import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro ao se comunicar com o servidor.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'O servidor demorou para responder. Tente novamente.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao ler dados locais.']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Email ou senha incorretos.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessão expirada. Faça login novamente.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Dados inválidos.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado. Tente novamente.']);
}

/// Converts DioException to user-friendly Failure
Failure mapDioExceptionToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      
      // Try to extract error message from API response
      String? apiMessage;
      if (responseData is Map) {
        apiMessage = responseData['error']?['message'] as String? ??
                     responseData['message'] as String?;
      }
      
      switch (statusCode) {
        case 400:
          return ValidationFailure(apiMessage ?? 'Dados inválidos.');
        case 401:
          return UnauthorizedFailure(apiMessage ?? 'Sessão expirada. Faça login novamente.');
        case 403:
          return const ServerFailure('Você não tem permissão para esta ação.');
        case 404:
          return NotFoundFailure(apiMessage ?? 'Recurso não encontrado.');
        case 409:
          return ServerFailure(apiMessage ?? 'Conflito de dados.');
        case 422:
          return ValidationFailure(apiMessage ?? 'Dados inválidos.');
        case 429:
          return const ServerFailure('Muitas tentativas. Aguarde um momento.');
        case 500:
        case 502:
        case 503:
          return const ServerFailure('Servidor indisponível. Tente novamente mais tarde.');
        default:
          return ServerFailure(apiMessage ?? 'Erro ao se comunicar com o servidor.');
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
