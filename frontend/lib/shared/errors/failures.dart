/// Base failure class for domain-level errors
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar dados locais']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sessão expirada — faça login novamente']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
