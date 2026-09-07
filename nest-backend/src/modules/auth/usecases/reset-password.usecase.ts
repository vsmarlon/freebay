import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  RecoveryCodeAlreadyUsedError,
  RecoveryCodeExpiredError,
  RecoveryCodeNotFoundError,
} from '@/shared/core/errors';
import { PasswordRecoveryRepository } from '../domain/repositories/password-recovery.repository';
import { UserRepository } from '../domain/repositories/user.repository';
import { ResetPasswordDTO } from '../dtos/password-recovery.dto';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';

@Injectable()
export class ResetPasswordUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly recoveryRepository: PasswordRecoveryRepository,
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

    const updateResult = await this.userRepository.update(user.id, { passwordHash });
    if (updateResult.isLeft()) return left(updateResult.value);

    const markResult = await this.recoveryRepository.markUsed(recovery.id);
    if (markResult.isLeft()) return left(markResult.value);

    await this.sessionRevoker.revokeAllSessions(user.id);

    return right(undefined);
  }
}
