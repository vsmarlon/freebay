export class AppError {
  constructor(
    public readonly code: string,
    public readonly message: string,
    public readonly statusCode: number = 400,
  ) {}
}

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

export class InsufficientBalanceError extends AppError {
  constructor() {
    super('INSUFFICIENT_BALANCE', 'Saldo insuficiente para saque', 422);
  }
}

export class NoRecipientError extends AppError {
  constructor() {
    super(
      'NO_RECIPIENT',
      'Nenhuma conta bancária cadastrada, configure seu recipient primeiro',
      422,
    );
  }
}

export class InvalidOrderStateError extends AppError {
  constructor(expected: string, current: string) {
    super('INVALID_ORDER_STATE', `Pedido deveria estar ${expected}, mas está ${current}`, 422);
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

export class AlreadyExistsError extends AppError {
  constructor(resource: string) {
    super('ALREADY_EXISTS', `${resource} já existe`, 409);
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
