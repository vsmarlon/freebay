import 'package:freebay/shared/errors/failures/failures.dart';

const String kGenericErrorMessage = 'Ocorreu um erro. Tente novamente.';

const Map<String, String> _messagesByCode = {
  'INVALID_CREDENTIALS': 'Email ou senha incorretos.',
  'EMAIL_ALREADY_EXISTS': 'Este email já está em uso.',
  'USERNAME_ALREADY_EXISTS': 'Este nome de usuário já está em uso.',
  'UNAUTHORIZED': 'Você precisa entrar para continuar.',
  'FORBIDDEN': 'Você não tem permissão para esta ação.',
  'NOT_FOUND': 'Não encontramos o que você procura.',
  'USER_NOT_FOUND': 'Usuário não encontrado.',
  'VALIDATION_ERROR': 'Dados inválidos. Verifique os campos e tente novamente.',
  'BAD_REQUEST': 'Não foi possível concluir. Verifique os dados.',
  'CONFLICT': 'Não foi possível concluir. Tente novamente.',
  'INVALID_ORDER_STATE': 'Este pedido não permite essa ação agora.',
  'INVALID_PHONE': 'Telefone inválido. Informe o DDD e o número.',
  'INVALID_TOKEN': 'Sessão inválida. Faça login novamente.',
  'SESSION_EXPIRED': 'Sua sessão expirou. Faça login novamente.',
  'INVALID_GOOGLE_TOKEN':
      'Não foi possível entrar com o Google. Tente novamente.',
  'UNVERIFIED_GOOGLE_EMAIL': 'Sua conta Google precisa ter o email verificado.',
  'RECOVERY_CODE_NOT_FOUND': 'Código de recuperação inválido ou expirado.',
  'RECOVERY_CODE_EXPIRED': 'Código de recuperação expirado.',
  'RECOVERY_CODE_ALREADY_USED': 'Este código já foi utilizado.',
  'RECOVERY_CODE_ATTEMPTS_EXCEEDED': 'Muitas tentativas. Aguarde um momento.',
  'PHONE_CODE_NOT_FOUND': 'Código de verificação inválido ou expirado.',
  'PHONE_CODE_EXPIRED': 'Código de verificação expirado.',
  'PHONE_CODE_ALREADY_USED': 'Este código já foi utilizado.',
  'PHONE_CODE_ATTEMPTS_EXCEEDED': 'Muitas tentativas. Aguarde um momento.',
  'PAYMENT_PROVIDER_ERROR':
      'Não foi possível processar o pagamento. Tente novamente.',
  'EMAIL_DELIVERY_FAILED': 'Não foi possível enviar o email. Tente novamente.',
  'ACCOUNT_DELETION_BLOCKED': 'Não é possível excluir a conta agora.',
  'ACCOUNT_SUSPENDED': 'Sua conta está suspensa.',
  'DB_ERROR': 'Servidor indisponível. Tente novamente mais tarde.',
  'INTERNAL_ERROR': 'Servidor indisponível. Tente novamente mais tarde.',
};

String? messageForCode(String? code) =>
    code == null ? null : _messagesByCode[code];

String userMessageOf(Object? error) =>
    error is Failure ? error.message : kGenericErrorMessage;
