import { AppError } from '@/shared/core/errors';

export class Failure extends AppError {
  constructor(message = 'Failure', code = 'FAILURE', statusCode = 400, detail?: string) {
    super(code, message, statusCode, detail);
    this.name = 'Failure';
  }
}

export class Failures {
  static default(message = 'Default failure'): Failure {
    return new Failure(message, 'DEFAULT_FAILURE', 400);
  }
}
