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
import { UserDatabaseRepository } from '@/modules/users';
import { ResetPasswordDTO } from '../dtos/password-recovery.dto';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';

@Injectable()
export class ResetPasswordUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly recoveryRepository: PasswordRecoveryDatabaseRepository,
    private readonly sessionRevoker: SessionRevokerService,
  ) {}

  async execute(input: ResetPasswordDTO): Promise<Either<AppError, void>> {
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

    const passwordHash = await bcrypt.hash(input.newPassword, 12);

    const userResult = await this.userRepository.findByEmail(input.email);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;

    if (!user) {
      return left(new RecoveryCodeNotFoundError());
    }

    const consumeResult = await this.recoveryRepository.consumeAndUpdatePassword(recovery.id, user.id, passwordHash);
    if (consumeResult.isLeft()) return left(consumeResult.value);
    if (!consumeResult.value) return left(new RecoveryCodeAlreadyUsedError());

    await this.sessionRevoker.revokeAllSessions(user.id);

    return right(undefined);
  }
}
