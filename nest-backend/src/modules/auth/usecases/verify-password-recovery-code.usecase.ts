import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  RecoveryCodeAlreadyUsedError,
  RecoveryCodeAttemptsExceededError,
  RecoveryCodeExpiredError,
  RecoveryCodeNotFoundError,
} from '@/shared/core/errors';
import { PasswordRecoveryRepository } from '../domain/repositories/password-recovery.repository';
import { VerifyPasswordRecoveryCodeDTO } from '../dtos/password-recovery.dto';

@Injectable()
export class VerifyPasswordRecoveryCodeUseCase {
  constructor(private readonly recoveryRepository: PasswordRecoveryRepository) {}

  async execute(input: VerifyPasswordRecoveryCodeDTO): Promise<Either<AppError, { verified: boolean }>> {
    const recoveryResult = await this.recoveryRepository.findLatestByEmail(input.email);
    if (recoveryResult.isLeft()) return left(recoveryResult.value);
    const recovery = recoveryResult.value;

    if (!recovery) {
      return left(new RecoveryCodeNotFoundError());
    }

    if (recovery.usedAt) {
      return left(new RecoveryCodeAlreadyUsedError());
    }

    if (recovery.expiresAt <= new Date()) {
      return left(new RecoveryCodeExpiredError());
    }

    if (recovery.attempts >= recovery.maxAttempts) {
      return left(new RecoveryCodeAttemptsExceededError());
    }

    const matches = await bcrypt.compare(input.code, recovery.codeHash);
    if (!matches) {
      await this.recoveryRepository.incrementAttempts(recovery.id);
      return left(new RecoveryCodeNotFoundError());
    }

    return right({ verified: true });
  }
}
