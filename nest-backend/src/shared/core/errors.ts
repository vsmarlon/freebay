export class AppError extends Error {
  readonly message: string;
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number = 400,
    public readonly detail?: string,
  ) {
    super(message);
    this.message = message;
    this.name = 'AppError';
  }
}

export type Failure = AppError;

export class InvalidCredentialsError extends AppError {
  constructor() {
    super('INVALID_CREDENTIALS', 'E-mail ou senha inválidos', 401);
  }
}

export class EmailAlreadyExistsError extends AppError {
  constructor() {
    super('EMAIL_ALREADY_EXISTS', 'Este e-mail já está em uso', 409);
  }
}

export class UsernameAlreadyExistsError extends AppError {
  constructor() {
    super('USERNAME_ALREADY_EXISTS', 'Este nome de usuário já está em uso', 409);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Não autorizado') {
    super('UNAUTHORIZED', message, 401);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super('NOT_FOUND', `${resource} não encontrado(a)`, 404);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Ação não permitida') {
    super('FORBIDDEN', message, 403);
  }
}

export class InvalidOrderStateError extends AppError {
  constructor(expected: string, current?: string) {
    super(
      'INVALID_ORDER_STATE',
      'Este pedido não permite essa ação agora',
      422,
      `expected=${expected} current=${current ?? 'n/a'}`,
    );
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super('VALIDATION_ERROR', message, 400);
  }
}

export class BadRequestError extends AppError {
  constructor(message = 'Requisição inválida') {
    super('BAD_REQUEST', message, 400);
  }
}

export class RecoveryCodeNotFoundError extends AppError {
  constructor() {
    super('RECOVERY_CODE_NOT_FOUND', 'Código de recuperação inválido ou expirado', 404);
  }
}

export class RecoveryCodeExpiredError extends AppError {
  constructor() {
    super('RECOVERY_CODE_EXPIRED', 'Código de recuperação expirado', 410);
  }
}

export class RecoveryCodeAttemptsExceededError extends AppError {
  constructor() {
    super('RECOVERY_CODE_ATTEMPTS_EXCEEDED', 'Limite de tentativas excedido', 429);
  }
}

export class RecoveryCodeAlreadyUsedError extends AppError {
  constructor() {
    super('RECOVERY_CODE_ALREADY_USED', 'Código de recuperação já utilizado', 409);
  }
}

export class PhoneCodeNotFoundError extends AppError {
  constructor() {
    super('PHONE_CODE_NOT_FOUND', 'Código de verificação inválido ou expirado', 404);
  }
}

export class PhoneCodeExpiredError extends AppError {
  constructor() {
    super('PHONE_CODE_EXPIRED', 'Código de verificação expirado', 410);
  }
}

export class PhoneCodeAttemptsExceededError extends AppError {
  constructor() {
    super('PHONE_CODE_ATTEMPTS_EXCEEDED', 'Limite de tentativas excedido', 429);
  }
}

export class PhoneCodeAlreadyUsedError extends AppError {
  constructor() {
    super('PHONE_CODE_ALREADY_USED', 'Código de verificação já utilizado', 409);
  }
}

export class InvalidPhoneError extends AppError {
  constructor(message = 'Telefone inválido. Informe o DDD e o número.') {
    super('INVALID_PHONE', message, 400);
  }
}

export class DatabaseError extends AppError {
  constructor(message = 'Erro no banco de dados') {
    super('DB_ERROR', message, 500);
  }
}

export class InternalServerError extends AppError {
  constructor(message = 'Erro interno do servidor') {
    super('INTERNAL_ERROR', message, 500);
  }
}

export class InvalidTokenError extends AppError {
  constructor(message = 'Token inválido') {
    super('INVALID_TOKEN', message, 401);
  }
}

export class SessionExpiredError extends AppError {
  constructor(message = 'Sessão expirada. Faça login novamente.') {
    super('SESSION_EXPIRED', message, 401);
  }
}

export class InvalidGoogleTokenError extends AppError {
  constructor(message = 'Token Google inválido') {
    super('INVALID_GOOGLE_TOKEN', message, 401);
  }
}

export class UnverifiedGoogleEmailError extends AppError {
  constructor(
    message = 'A conta Google precisa ter o e-mail verificado para ser vinculada a uma conta existente',
  ) {
    super('UNVERIFIED_GOOGLE_EMAIL', message, 403);
  }
}

export class UserNotFoundError extends AppError {
  constructor(message = 'Usuário não encontrado') {
    super('USER_NOT_FOUND', message, 404);
  }
}

export class PaymentProviderError extends AppError {
  constructor(message = 'Erro no provedor de pagamento', statusCode = 500) {
    super('PAYMENT_PROVIDER_ERROR', message, statusCode);
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Conflito de dados') {
    super('CONFLICT', message, 409);
  }
}

export class EmailDeliveryFailedError extends AppError {
  constructor(message = 'Falha ao enviar e-mail') {
    super('EMAIL_DELIVERY_FAILED', message, 500);
  }
}

export class AccountDeletionBlockedError extends AppError {
  constructor(reasons: string[]) {
    super(
      'ACCOUNT_DELETION_BLOCKED',
      `Não é possível excluir a conta agora: ${reasons.join('; ')}`,
      409,
    );
  }
}

export class AccountSuspendedError extends AppError {
  constructor(reason?: string | null) {
    super(
      'ACCOUNT_SUSPENDED',
      reason ? `Conta suspensa: ${reason}` : 'Conta suspensa',
      403,
    );
  }
}
