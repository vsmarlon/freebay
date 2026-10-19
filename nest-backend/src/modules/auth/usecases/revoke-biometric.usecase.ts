import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { SessionTokenService } from '../services/session-token.service';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';

@Injectable()
export class RevokeBiometricUseCase {
  constructor(
    private readonly tokens: SessionTokenService,
    private readonly credentials: BiometricCredentialService,
  ) {}

  async execute(payload: { jti: string; exp: number; sid: string }): Promise<Either<AppError, { message: string }>> {
    await this.tokens.revoke(payload.jti, payload.exp);
    await this.credentials.revoke(payload.sid);
    return right({ message: 'Token biométrico revogado' });
  }
}
