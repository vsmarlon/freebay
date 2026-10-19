import { Injectable } from '@nestjs/common';
import { AppError, InvalidCredentialsError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { BiometricCredentialService, BiometricOperation, isStepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { BiometricChallengeDTO } from '../dtos/auth.dto';

@Injectable()
export class CreateBiometricChallengeUseCase {
  constructor(
    private readonly validator: JwtTokenValidatorService,
    private readonly credentials: BiometricCredentialService,
  ) {}

  async execute(input: BiometricChallengeDTO): Promise<Either<AppError, { challengeId: string; challenge: string }>> {
    const operation = this.operation(input);
    if (!operation) return left(new InvalidCredentialsError());
    let user;
    try {
      user = await this.validator.verifyAndValidate(input.biometricToken, [JwtTokenType.BIOMETRIC]);
    } catch {
      return left(new InvalidCredentialsError());
    }
    const challenge = await this.credentials.createChallenge(user, operation);
    return challenge ? right(challenge) : left(new InvalidCredentialsError());
  }

  private operation(input: BiometricChallengeDTO): BiometricOperation | null {
    if (input.purpose === 'login') {
      return input.stepUpPurpose === undefined && input.resourceId === undefined ? { purpose: 'login' } : null;
    }
    if (!input.stepUpPurpose || !isStepUpPurpose(input.stepUpPurpose)) return null;
    if (input.stepUpPurpose === 'cancel_order') {
      return input.resourceId ? { purpose: 'step_up', stepUpPurpose: input.stepUpPurpose, resourceId: input.resourceId } : null;
    }
    return input.resourceId === undefined
      ? { purpose: 'step_up', stepUpPurpose: input.stepUpPurpose }
      : null;
  }
}
