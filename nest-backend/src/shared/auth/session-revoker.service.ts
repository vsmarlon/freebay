import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

export const SESSION_INVALID_BEFORE_PREFIX = 'user_tokens_invalid_before:';
export const SESSION_INVALID_BEFORE_TTL_SECONDS = 30 * 24 * 60 * 60;
export const SESSION_FAMILY_REVOKED_PREFIX = 'session_family_revoked:';
export const DEFAULT_ACCESS_TOKEN_TTL = '15m';
export const DEFAULT_REFRESH_TOKEN_TTL = '7d';
export const DEFAULT_BIOMETRIC_TOKEN_TTL = '7d';

type SessionOriginClaims = { iat?: unknown; issuedAtMs?: unknown; sessionStartedAtMs?: unknown };

export function sessionOriginMs(payload: SessionOriginClaims): number | null {
  if (payload.sessionStartedAtMs !== undefined) return validDateMs(payload.sessionStartedAtMs) ? payload.sessionStartedAtMs : null;
  if (payload.issuedAtMs !== undefined) return validDateMs(payload.issuedAtMs) ? payload.issuedAtMs : null;
  if (payload.iat !== undefined && typeof payload.iat === 'number' && Number.isSafeInteger(payload.iat)) {
    const legacyMs = payload.iat * 1000;
    return validDateMs(legacyMs) ? legacyMs : null;
  }
  return null;
}

function validDateMs(value: unknown): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && Math.abs(value) <= 8.64e15 &&
    Number.isFinite(new Date(value).getTime());
}

export function isIssuedBeforeCutoff(payload: SessionOriginClaims, invalidBefore: string | null): boolean {
  if (!invalidBefore) return false;
  const cutoffMs = Number(invalidBefore);
  if (!Number.isFinite(cutoffMs)) return true;
  const issuedAtMs = sessionOriginMs(payload);
  return issuedAtMs === null || issuedAtMs <= cutoffMs;
}

@Injectable()
export class SessionRevokerService {
  constructor(
    private readonly redisService: RedisService,
    private readonly config: ConfigService,
    private readonly authSessionState: AuthSessionStateDatabaseRepository,
  ) {}

  async revokeAllSessions(userId: string): Promise<void> {
    const cutoff = new Date();
    await this.authSessionState.advanceInvalidBefore(userId, cutoff);
    try {
      await this.redisService.add(
        `${SESSION_INVALID_BEFORE_PREFIX}${userId}`,
        cutoff.getTime().toString(),
        SESSION_INVALID_BEFORE_TTL_SECONDS,
      );
    } catch {
      // Durable cutoff is authoritative; Redis is only a cache.
    }
  }

  async clearRevocation(userId: string): Promise<void> {
    await this.redisService.del(`${SESSION_INVALID_BEFORE_PREFIX}${userId}`);
  }

  async revokeFamily(sid: string): Promise<void> {
    const ttl = Math.max(
      SESSION_INVALID_BEFORE_TTL_SECONDS,
      configuredSeconds(this.config.get('JWT_REFRESH_EXPIRES_IN', DEFAULT_REFRESH_TOKEN_TTL)),
      configuredSeconds(this.config.get('JWT_BIOMETRIC_EXPIRES_IN', DEFAULT_BIOMETRIC_TOKEN_TTL)),
      configuredSeconds(this.config.get('JWT_EXPIRES_IN', DEFAULT_ACCESS_TOKEN_TTL)),
    );
    await this.redisService.add(`${SESSION_FAMILY_REVOKED_PREFIX}${sid}`, '1', ttl);
  }

}

function configuredSeconds(value: string): number {
  const match = /^\s*(\d+(?:\.\d+)?)\s*(ms|s|m|h|d|w|y)\s*$/i.exec(value);
  if (!match) return SESSION_INVALID_BEFORE_TTL_SECONDS;
  const amount = Number(match[1]);
  const multiplier = match[2]?.toLowerCase() === 'ms' ? 0.001
    : match[2]?.toLowerCase() === 's' ? 1
      : match[2]?.toLowerCase() === 'm' ? 60
        : match[2]?.toLowerCase() === 'h' ? 3600
          : match[2]?.toLowerCase() === 'd' ? 86_400
            : match[2]?.toLowerCase() === 'w' ? 604_800 : 31_557_600;
  return Math.ceil(amount * multiplier);
}
