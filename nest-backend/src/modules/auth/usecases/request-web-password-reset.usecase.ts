import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, createHash, randomBytes } from 'node:crypto';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';
import { RequestWebPasswordResetDTO } from '../dtos/web-password-reset.dto';
import { normalizeEmail } from '@/shared/utils/normalize-email';
import { dispatchAuthEmailJob } from '../utils/dispatch-auth-email-job';

const WINDOW_SECONDS = 3600;
const TTL_MS = 10 * 60 * 1000;

@Injectable()
export class RequestWebPasswordResetUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly recovery: PasswordRecoveryDatabaseRepository,
    private readonly email: ResendService,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  async execute(input: RequestWebPasswordResetDTO): Promise<Either<AppError, void>> {
    const email = normalizeEmail(input.email);
    const key = createHmac('sha256', this.config.getOrThrow<string>('JWT_SECRET')).update(email).digest('hex');
    if (await this.redis.incrementWithExpiry(`web-password-reset:${key}`, WINDOW_SECONDS) > 3) return right(undefined);
    const cooldown = `web-password-reset-cooldown:${key}`;
    if (!await this.redis.setIfAbsent(cooldown, '1', 60)) return right(undefined);

    dispatchAuthEmailJob(async () => {
      const userResult = await this.users.findByEmail(email);
      if (userResult.isLeft()) return;
      const user = userResult.value;
      if (!user || !user.passwordHash) return;

      const removed = await this.recovery.deleteManyForUser(user.id);
      if (removed.isLeft()) return;
      const token = randomBytes(32).toString('base64url');
      const codeHash = `web-reset:${createHash('sha256').update(token).digest('hex')}`;
      const created = await this.recovery.create({ user: { connect: { id: user.id } }, codeHash, expiresAt: new Date(Date.now() + TTL_MS), maxAttempts: 5 });
      if (created.isLeft()) return;

      try {
        const messageId = await this.email.sendWebPasswordReset(user.email, token, input.locale, created.value.id);
        if (!messageId) {
          await Promise.allSettled([this.recovery.delete(created.value.id), this.redis.del(cooldown)]);
          return;
        }
        await this.recovery.markSent(created.value.id, messageId);
      } catch {
        await Promise.allSettled([this.recovery.delete(created.value.id), this.redis.del(cooldown)]);
      }
    });
    return right(undefined);
  }
}
