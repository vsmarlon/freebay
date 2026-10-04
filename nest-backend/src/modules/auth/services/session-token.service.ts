import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { JwtSignOptions } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserRole } from '@prisma/client';

export const DEFAULT_ACCESS_TOKEN_TTL = '15m';
export const DEFAULT_REFRESH_TOKEN_TTL = '7d';
export const DEFAULT_BIOMETRIC_TOKEN_TTL = '7d';
export const BIOMETRIC_ENROLLMENT_CLAIM_TTL_SECONDS = 300;

@Injectable()
export class SessionTokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  generate(userId: string, role: UserRole, authenticatedAtMs: number | null = Date.now()) {
    return {
      token: this.sign(userId, role, JwtTokenType.ACCESS, this.config.get('JWT_EXPIRES_IN', DEFAULT_ACCESS_TOKEN_TTL), authenticatedAtMs),
      refreshToken: this.sign(userId, role, JwtTokenType.REFRESH, this.config.get('JWT_REFRESH_EXPIRES_IN', DEFAULT_REFRESH_TOKEN_TTL), authenticatedAtMs),
    };
  }

  generateBiometric(userId: string, role: UserRole) {
    return this.sign(userId, role, JwtTokenType.BIOMETRIC, this.config.get('JWT_BIOMETRIC_EXPIRES_IN', DEFAULT_BIOMETRIC_TOKEN_TTL));
  }

  async revoke(jti?: string, exp?: number): Promise<void> {
    if (!jti || !exp) return;
    const ttl = exp - Math.floor(Date.now() / 1000);
    if (ttl > 0) await this.redisService.add(`blacklist:${jti}`, '1', ttl);
  }

  async claimRefresh(jti: string, exp: number): Promise<boolean> {
    const ttl = exp - Math.floor(Date.now() / 1000);
    return ttl > 0 && this.redisService.setIfAbsent(`refresh-claimed:${jti}`, '1', ttl);
  }

  async claimBiometric(jti: string, exp: number): Promise<boolean> {
    const ttl = exp - Math.floor(Date.now() / 1000);
    return ttl > 0 && this.redisService.setIfAbsent(`biometric-claimed:${jti}`, '1', ttl);
  }

  async claimBiometricEnrollment(jti: string, exp?: number): Promise<boolean> {
    const ttl = Math.max(1, (exp ?? Math.floor(Date.now() / 1000) + BIOMETRIC_ENROLLMENT_CLAIM_TTL_SECONDS) - Math.floor(Date.now() / 1000));
    return this.redisService.setIfAbsent(`biometric-enrollment-claimed:${jti}`, '1', ttl);
  }

  private sign(userId: string, role: UserRole, type: JwtTokenType, expiresIn: string, authenticatedAtMs?: number | null) {
    return this.jwtService.sign(
      {
        userId, role, type, jti: randomUUID(), issuedAtMs: Date.now(),
        ...(authenticatedAtMs === null || authenticatedAtMs === undefined ? {} : { authenticatedAtMs }),
      } satisfies JwtPayload,
      { expiresIn: expiresIn as JwtSignOptions['expiresIn'] },
    );
  }
}
