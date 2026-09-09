import { Injectable } from '@nestjs/common';
import { RedisService } from '@/shared/infra/redis/redis.service';

export const SESSION_INVALID_BEFORE_PREFIX = 'user_tokens_invalid_before:';
const SESSION_INVALID_BEFORE_TTL_SECONDS = 60 * 60 * 24 * 30;

@Injectable()
export class SessionRevokerService {
  constructor(private readonly redisService: RedisService) {}

  async revokeAllSessions(userId: string): Promise<void> {
    await this.redisService.add(
      `${SESSION_INVALID_BEFORE_PREFIX}${userId}`,
      Date.now().toString(),
      SESSION_INVALID_BEFORE_TTL_SECONDS,
    );
  }

  async clearRevocation(userId: string): Promise<void> {
    await this.redisService.del(`${SESSION_INVALID_BEFORE_PREFIX}${userId}`);
  }
}
