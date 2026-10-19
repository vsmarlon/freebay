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
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { VerifyPasswordRecoveryCodeDTO } from '../dtos/password-recovery.dto';

@Injectable()
export class VerifyPasswordRecoveryCodeUseCase {
  constructor(private readonly recoveryRepository: PasswordRecoveryDatabaseRepository) {}

  async execute(input: VerifyPasswordRecoveryCodeDTO): Promise<Either<AppError, void>> {
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

    if (recovery.codeHash.startsWith('web-reset:')) {
      return left(new RecoveryCodeNotFoundError());
    }

    const reservation = await this.recoveryRepository.reserveAttempt(recovery.id);
    if (reservation.isLeft()) return left(reservation.value);
    if (!reservation.value) return left(new RecoveryCodeAttemptsExceededError());

    const matches = await bcrypt.compare(input.code, recovery.codeHash);
    if (!matches) {
      return left(new RecoveryCodeNotFoundError());
    }

    return right(undefined);
  }
}
