import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { JwtSignOptions } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';

@Injectable()
export class SessionTokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  generate(userId: string, role: string) {
    return {
      token: this.sign(userId, role, JwtTokenType.ACCESS, this.config.get('JWT_EXPIRES_IN', '15m')),
      refreshToken: this.sign(userId, role, JwtTokenType.REFRESH, this.config.get('JWT_REFRESH_EXPIRES_IN', '7d')),
      biometricToken: this.sign(userId, role, JwtTokenType.BIOMETRIC, this.config.get('JWT_BIOMETRIC_EXPIRES_IN', '7d')),
    };
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

  private sign(userId: string, role: string, type: JwtTokenType, expiresIn: string) {
    return this.jwtService.sign(
      { userId, role, type, jti: randomUUID(), issuedAtMs: Date.now() } satisfies JwtPayload,
      { expiresIn: expiresIn as JwtSignOptions['expiresIn'] },
    );
  }
}
