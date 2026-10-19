import { Injectable } from '@nestjs/common';
import { createHash } from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { Either, left, right } from '@/shared/core/either';
import { AppError, RecoveryCodeAttemptsExceededError, RecoveryCodeNotFoundError } from '@/shared/core/errors';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResetWebPasswordDTO } from '../dtos/web-password-reset.dto';

@Injectable()
export class ResetWebPasswordUseCase {
  constructor(
    private readonly recovery: PasswordRecoveryDatabaseRepository,
    private readonly sessionRevoker: SessionRevokerService,
  ) {}

  async execute(input: ResetWebPasswordDTO): Promise<Either<AppError, void>> {
    if (!/^[A-Za-z0-9_-]{43}$/.test(input.token)) return left(new RecoveryCodeNotFoundError());
    const codeHash = `web-reset:${createHash('sha256').update(input.token).digest('hex')}`;
    const found = await this.recovery.findByCodeHash(codeHash);
    if (found.isLeft()) return left(found.value);
    const recovery = found.value;
    if (!recovery || recovery.usedAt || recovery.expiresAt <= new Date()) return left(new RecoveryCodeNotFoundError());

    const reserved = await this.recovery.reserveAttempt(recovery.id);
    if (reserved.isLeft()) return left(reserved.value);
    if (!reserved.value) return left(new RecoveryCodeAttemptsExceededError());
    const passwordHash = await bcrypt.hash(input.newPassword, 12);
    const consumed = await this.recovery.consumeAndUpdatePassword(recovery.id, recovery.userId, passwordHash);
    if (consumed.isLeft()) return left(consumed.value);
    if (!consumed.value) return left(new RecoveryCodeNotFoundError());
    await this.sessionRevoker.revokeAllSessions(recovery.userId);
    return right(undefined);
  }
}
