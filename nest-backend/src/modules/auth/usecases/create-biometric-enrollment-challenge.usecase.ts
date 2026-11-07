import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UnauthorizedError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { BiometricCredentialService, InvalidBiometricPublicKeyError } from '@/shared/auth/biometric-credential.service';

@Injectable()
export class CreateBiometricEnrollmentChallengeUseCase {
  constructor(private readonly credentials: BiometricCredentialService) {}

  async execute(user: AuthUser, publicKey: string): Promise<Either<AppError, { challengeId: string; challenge: string }>> {
    try {
      const challenge = await this.credentials.createEnrollmentChallenge(user, publicKey);
      return challenge ? right(challenge) : left(new UnauthorizedError('Authenticated session required'));
    } catch (error: unknown) {
      if (error instanceof InvalidBiometricPublicKeyError) return left(new UnauthorizedError('Invalid biometric public key'));
      throw error;
    }
  }
}
