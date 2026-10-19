import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { createHmac, randomInt } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { RequestPasswordRecoveryDTO } from '../dtos/password-recovery.dto';
import { ResendService } from '../services/resend.service';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { normalizeEmail } from '@/shared/utils/normalize-email';
import { dispatchAuthEmailJob } from '../utils/dispatch-auth-email-job';

const REQUEST_LIMIT = 3;
const REQUEST_WINDOW_SECONDS = 60 * 60;

@Injectable()
export class RequestPasswordRecoveryUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly recoveryRepository: PasswordRecoveryDatabaseRepository,
    private readonly resendService: ResendService,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  async execute(input: RequestPasswordRecoveryDTO): Promise<Either<AppError, void>> {
    const email = normalizeEmail(input.email);
    const emailKey = createHmac('sha256', this.config.getOrThrow<string>('JWT_SECRET')).update(email).digest('hex');
    const cooldownKey = `password-recovery-cooldown:${emailKey}`;
    const requests = await this.redis.incrementWithExpiry(`password-recovery:${emailKey}`, REQUEST_WINDOW_SECONDS);
    if (requests > REQUEST_LIMIT) return right(undefined);
    if (!await this.redis.setIfAbsent(cooldownKey, '1', 60)) return right(undefined);

    dispatchAuthEmailJob(async () => {
      const userResult = await this.userRepository.findByEmail(email);
      if (userResult.isLeft()) return;
      const user = userResult.value;
      if (!user) return;

      const deleteResult = await this.recoveryRepository.deleteManyForUser(user.id);
      if (deleteResult.isLeft()) return;

      const code = randomInt(100_000, 1_000_000).toString();
      const codeHash = await bcrypt.hash(code, 10);
      const createResult = await this.recoveryRepository.create({
        user: { connect: { id: user.id } },
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        maxAttempts: 5,
      });
      if (createResult.isLeft()) return;

      let resendMessageId: string | null;
      try {
        resendMessageId = await this.resendService.sendRecoveryCode(user.email, code);
      } catch {
        await Promise.allSettled([
          this.recoveryRepository.delete(createResult.value.id),
          this.redis.del(cooldownKey),
        ]);
        return;
      }
      if (!resendMessageId) {
        await Promise.allSettled([
          this.recoveryRepository.delete(createResult.value.id),
          this.redis.del(cooldownKey),
        ]);
        return;
      }

      await this.recoveryRepository.markSent(createResult.value.id, resendMessageId);
    });
    return right(undefined);
  }
}
