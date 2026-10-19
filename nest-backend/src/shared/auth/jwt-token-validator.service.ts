import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { isIssuedBeforeCutoff, sessionOriginMs, SESSION_FAMILY_REVOKED_PREFIX, SESSION_INVALID_BEFORE_PREFIX, SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

@Injectable()
export class JwtTokenValidatorService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
    private readonly sessionRevoker: SessionRevokerService,
    private readonly authSessionState: AuthSessionStateDatabaseRepository,
  ) {}

  async verifyAndValidate<T extends object = AuthUser>(
    token: string,
    allowedTypes: Array<JwtTokenType> = [JwtTokenType.ACCESS],
  ): Promise<T> {
    const payload = await this.jwtService.verifyAsync<T & JwtPayload>(token, {
      secret: this.config.getOrThrow('JWT_SECRET'),
    });

    if (!payload.type || !allowedTypes.includes(payload.type)) {
      throw new UnauthorizedException('Tipo de token inválido');
    }

    const sessionStartedAtMs = sessionOriginMs(payload);
    if (sessionStartedAtMs === null) throw new UnauthorizedException('Token sem origem de sessão válida');
    payload.sessionStartedAtMs = sessionStartedAtMs;

    if (payload.jti && (await this.redisService.exists(`blacklist:${payload.jti}`))) {
      if (payload.type === JwtTokenType.REFRESH && payload.sid) {
        await this.sessionRevoker.revokeFamily(payload.sid);
      }
      throw new UnauthorizedException('Token revogado');
    }

    if (payload.sid && await this.redisService.exists(`${SESSION_FAMILY_REVOKED_PREFIX}${payload.sid}`)) {
      throw new UnauthorizedException('Família de sessão revogada');
    }

    if (payload.userId) {
      const [durableCutoff, cachedCutoff] = await Promise.all([
        this.authSessionState.findInvalidBefore(payload.userId),
        this.redisService.get(`${SESSION_INVALID_BEFORE_PREFIX}${payload.userId}`),
      ]);
      const invalidBefore = durableCutoff && cachedCutoff
        ? String(Math.max(durableCutoff.getTime(), Number(cachedCutoff)))
        : durableCutoff?.getTime().toString() ?? cachedCutoff;
      if (isIssuedBeforeCutoff(payload, invalidBefore)) {
        throw new UnauthorizedException('Sessão expirada');
      }
    }

    return payload;
  }
}
