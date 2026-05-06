import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  RecoveryCodeAlreadyUsedError,
  RecoveryCodeExpiredError,
  RecoveryCodeNotFoundError,
} from '@/shared/core/errors';
import { PrismaPasswordRecoveryRepository } from '../repositories/password-recovery.repository';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { ResetPasswordDTO } from '../dtos/password-recovery.dto';

@Injectable()
export class ResetPasswordUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private recoveryRepository: PrismaPasswordRecoveryRepository,
  ) {}

  async execute(input: ResetPasswordDTO): Promise<Either<AppError, { reset: boolean }>> {
    const recovery = await this.recoveryRepository.findLatestByEmail(input.email);

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
    const user = await this.userRepository.findByEmail(input.email);

    if (!user) {
      return left(new RecoveryCodeNotFoundError());
    }

    await this.userRepository.update(user.id, { passwordHash });
    await this.recoveryRepository.markUsed(recovery.id);

    return right({ reset: true });
  }
}
