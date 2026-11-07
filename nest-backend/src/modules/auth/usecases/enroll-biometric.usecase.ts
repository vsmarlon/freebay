import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UnauthorizedError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { BiometricCredentialService, InvalidBiometricPublicKeyError, isEnrollmentSession, StepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { StepUpService } from '@/shared/auth/step-up.service';

@Injectable()
export class EnrollBiometricUseCase {
  constructor(
    private readonly tokens: SessionTokenService,
    private readonly credentials: BiometricCredentialService,
    private readonly stepUp: StepUpService,
  ) {}

  async execute(user: AuthUser, stepUpToken: string | undefined, publicKey: string, challengeId?: string, signature?: string): Promise<Either<AppError, { biometricToken: string }>> {
    if (!isEnrollmentSession(user) || !user.role) return left(new UnauthorizedError('Authenticated session required'));
    const verified = challengeId && signature
      ? await this.credentials.verifyEnrollmentAndConsume(user, publicKey, challengeId, signature)
      : !!stepUpToken && await this.stepUp.consume(stepUpToken, user.userId, StepUpPurpose.BIOMETRIC_ENROLL);
    if (!verified) {
      return left(new UnauthorizedError('Biometric enrollment proof required'));
    }
    const sid = user.sid;
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
