import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { JwtSignOptions } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserRole } from '@prisma/client';
import {
  DEFAULT_ACCESS_TOKEN_TTL,
  DEFAULT_BIOMETRIC_TOKEN_TTL,
  DEFAULT_REFRESH_TOKEN_TTL,
  SessionRevokerService,
} from '@/shared/auth/session-revoker.service';

export { DEFAULT_ACCESS_TOKEN_TTL, DEFAULT_BIOMETRIC_TOKEN_TTL, DEFAULT_REFRESH_TOKEN_TTL };

@Injectable()
export class SessionTokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
    private readonly sessionRevoker: SessionRevokerService,
  ) {}

  generate(userId: string, role: UserRole, authenticatedAtMs: number | null, sid: string | undefined, sessionStartedAtMs: number) {
    const sessionId = sid ?? randomUUID();
    return {
      token: this.sign(userId, role, JwtTokenType.ACCESS, this.config.get('JWT_EXPIRES_IN', DEFAULT_ACCESS_TOKEN_TTL), authenticatedAtMs, sessionId, sessionStartedAtMs),
      refreshToken: this.sign(userId, role, JwtTokenType.REFRESH, this.config.get('JWT_REFRESH_EXPIRES_IN', DEFAULT_REFRESH_TOKEN_TTL), authenticatedAtMs, sessionId, sessionStartedAtMs),
    };
  }

  generateBiometric(userId: string, role: UserRole, sid: string | undefined, sessionStartedAtMs: number) {
    return this.sign(userId, role, JwtTokenType.BIOMETRIC, this.config.get('JWT_BIOMETRIC_EXPIRES_IN', DEFAULT_BIOMETRIC_TOKEN_TTL), null, sid ?? randomUUID(), sessionStartedAtMs);
  }

  async revoke(jti?: string, exp?: number): Promise<void> {
    if (!jti || !exp) return;
    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) await this.redisService.add(`blacklist:${jti}`, '1', ttl);
  }

  async claimRefresh(jti: string, exp: number, sid?: string): Promise<boolean> {
    const ttl = exp - Math.floor(Date.now() / 1000);
    const claimed = ttl > 0 && await this.redisService.setIfAbsent(`refresh-claimed:${jti}`, '1', ttl);
    if (!claimed && sid) await this.revokeFamily(sid);
    return claimed;
  }

  async claimBiometric(jti: string, exp: number, sid?: string): Promise<boolean> {
    const ttl = exp - Math.floor(Date.now() / 1000);
    const claimed = ttl > 0 && await this.redisService.setIfAbsent(`biometric-claimed:${jti}`, '1', ttl);
    if (!claimed && sid) await this.revokeFamily(sid);
    return claimed;
  }

  async revokeFamily(sid: string): Promise<void> {
    await this.sessionRevoker.revokeFamily(sid);
  }

  private sign(userId: string, role: UserRole, type: JwtTokenType, expiresIn: string, authenticatedAtMs: number | null, sid: string | undefined, sessionStartedAtMs: number) {
    return this.jwtService.sign(
      {
        userId, role, type, jti: randomUUID(), issuedAtMs: Date.now(), sessionStartedAtMs, ...(sid ? { sid } : {}),
        ...(authenticatedAtMs === null || authenticatedAtMs === undefined ? {} : { authenticatedAtMs }),
      } satisfies JwtPayload,
      { expiresIn: expiresIn as JwtSignOptions['expiresIn'] },
    );
  }
}
