import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import { StepUpPurpose, isStepUpPurpose } from './biometric-credential.service';
import { RedisService } from '@/shared/infra/redis/redis.service';

const STEP_UP_TTL_SECONDS = 5 * 60;
const STEP_UP_ISSUER = 'freebay-step-up';

type StepUpClaims = {
  sub: string;
  purpose: StepUpPurpose;
  resourceId?: string;
  jti: string;
  iss: string;
  exp: number;
};

@Injectable()
export class StepUpService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly redis: RedisService,
  ) {}

  async issue(userId: string, purpose: StepUpPurpose, resourceId?: string): Promise<{ stepUpToken: string; expiresAt: string }> {
    const now = Math.floor(Date.now() / 1000);
    const stepUpToken = this.jwt.sign({
      sub: userId, purpose, ...(resourceId ? { resourceId } : {}), jti: randomUUID(), iss: STEP_UP_ISSUER,
    }, { secret: this.config.getOrThrow<string>('JWT_SECRET'), expiresIn: STEP_UP_TTL_SECONDS });
    return { stepUpToken, expiresAt: new Date((now + STEP_UP_TTL_SECONDS) * 1000).toISOString() };
  }

  async consume(token: string, userId: string, purpose: StepUpPurpose, resourceId?: string): Promise<boolean> {
    let claims: StepUpClaims;
    try {
      claims = await this.jwt.verifyAsync<StepUpClaims>(token, { secret: this.config.getOrThrow<string>('JWT_SECRET'), issuer: STEP_UP_ISSUER });
    } catch {
      return false;
    }
    if (claims.sub !== userId || claims.purpose !== purpose || claims.resourceId !== resourceId ||
      !isStepUpPurpose(claims.purpose) || !claims.jti || !claims.exp) return false;
    const ttl = claims.exp - Math.floor(Date.now() / 1000);
    return ttl > 0 && this.redis.setIfAbsent(`step-up:consumed:${claims.jti}`, '1', ttl);
  }
}
