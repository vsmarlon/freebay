import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { JwtPayload } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';

@Injectable()
export class JwtTokenValidatorService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  async verifyAndValidate(
    token: string,
    allowedTypes: Array<'access' | 'refresh'> = ['access'],
  ): Promise<JwtPayload> {
    const payload = await this.jwtService.verifyAsync<JwtPayload>(token, {
      secret: this.config.getOrThrow('JWT_SECRET'),
    });

    if (!payload.type || !allowedTypes.includes(payload.type)) {
      throw new UnauthorizedException('Tipo de token inválido');
    }

    if (payload.jti && (await this.redisService.exists(`blacklist:${payload.jti}`))) {
      throw new UnauthorizedException('Token revogado');
    }

    if (payload.userId && payload.iat) {
      const invalidBefore = await this.redisService.get(`user_tokens_invalid_before:${payload.userId}`);
      if (invalidBefore && payload.iat < Number(invalidBefore)) {
        throw new UnauthorizedException('Sessão expirada');
      }
    }

    return payload;
  }
}
