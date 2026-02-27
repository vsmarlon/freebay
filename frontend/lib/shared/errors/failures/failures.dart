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

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao ler dados locais.']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Credenciais inválidas.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro desconhecido.']);
}
