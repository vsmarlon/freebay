import { redisService } from './redis.service';

const BLACKLIST_PREFIX = 'token:blacklist:';

export class TokenBlacklistService {
  async add(jti: string, expiresInSeconds: number): Promise<void> {
    const redis = redisService.getInstance();
    await redis.setex(`${BLACKLIST_PREFIX}${jti}`, expiresInSeconds, '1');
  }

  async isBlacklisted(jti: string): Promise<boolean> {
    try {
      const redis = redisService.getInstance();
      const result = await redis.get(`${BLACKLIST_PREFIX}${jti}`);
      return result === '1';
    } catch {
      // If Redis is unavailable, allow the request through.
      // The JWT signature is already verified at this point.
      return false;
    }
  }
}

export const tokenBlacklistService = new TokenBlacklistService();
