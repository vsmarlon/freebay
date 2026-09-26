import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { SessionTokenService } from '../services/session-token.service';

@Injectable()
export class RevokeBiometricUseCase {
  constructor(private readonly tokens: SessionTokenService) {}

  async execute(payload: { jti: string; exp: number }): Promise<Either<AppError, { message: string }>> {
    await this.tokens.revoke(payload.jti, payload.exp);
    return right({ message: 'Token biométrico revogado' });
  }
}
