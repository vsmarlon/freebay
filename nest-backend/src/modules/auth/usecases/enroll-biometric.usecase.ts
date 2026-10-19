import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UnauthorizedError } from '@/shared/core/errors';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { BiometricCredentialService, InvalidBiometricPublicKeyError } from '@/shared/auth/biometric-credential.service';
import { StepUpService } from '@/shared/auth/step-up.service';

@Injectable()
export class EnrollBiometricUseCase {
  constructor(
    private readonly tokens: SessionTokenService,
    private readonly credentials: BiometricCredentialService,
    private readonly stepUp: StepUpService,
  ) {}

  async execute(user: AuthUser, stepUpToken: string, publicKey: string): Promise<Either<AppError, { biometricToken: string }>> {
    if (!user.userId || !user.role || user.type !== JwtTokenType.ACCESS ||
      typeof user.sessionStartedAtMs !== 'number' || !Number.isSafeInteger(user.sessionStartedAtMs) ||
      !await this.stepUp.consume(stepUpToken, user.userId, 'biometric_enroll')) {
      return left(new UnauthorizedError('Fresh step-up proof required'));
    }
    const sid = user.sid ?? randomUUID();
    try {
      await this.credentials.register(user.userId, sid, publicKey);
    } catch (error: unknown) {
      if (error instanceof InvalidBiometricPublicKeyError) {
        return left(new UnauthorizedError('Invalid biometric public key'));
      }
      throw error;
    }
    return right({ biometricToken: this.tokens.generateBiometric(user.userId, user.role, sid, user.sessionStartedAtMs) });
  }
}
