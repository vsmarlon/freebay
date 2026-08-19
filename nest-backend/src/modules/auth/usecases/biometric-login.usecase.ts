import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidCredentialsError, NotFoundError } from '@/shared/core/errors';
import { UserRepository } from '../domain/repositories/user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { LoginResponse, toLoginResponse } from '../mappers/auth.mapper';
import { AuthUser, JwtTokenType } from '@/shared/core/types';

@Injectable()
export class BiometricLoginUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
  ) {}

  async execute(biometricToken: string): Promise<Either<AppError, LoginResponse>> {
    // 1. Verify JWT signature + expiry
    let payload: AuthUser;
    try {
      payload = await this.jwtService.verifyAsync<AuthUser>(biometricToken, {
        secret: this.configService.getOrThrow<string>('JWT_SECRET'),
      });
    } catch {
      return left(new InvalidCredentialsError());
    }

    // 2. Must be a biometric-type token
    if (payload.type !== JwtTokenType.BIOMETRIC) {
      return left(new InvalidCredentialsError());
    }

    // 3. Check Redis blacklist (revoked / already rotated)
    if (payload.jti) {
      const blacklisted = await this.redisService.get(`blacklist:${payload.jti}`);
      if (blacklisted) {
        return left(new InvalidCredentialsError());
      }
    }

    // 4. Check global invalidation cutoff (e.g. password reset)
    if (payload.userId && payload.iat) {
      const invalidBefore = await this.redisService.get(`user_tokens_invalid_before:${payload.userId}`);
      if (invalidBefore && payload.iat < Number(invalidBefore)) {
        return left(new AppError('SESSION_EXPIRED', 'Sessão expirada. Faça login novamente.', 401));
      }
    }

    // 5. Look up the user
    const userResult = await this.userRepository.findById(payload.userId!);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;

    if (!user) {
      return left(new NotFoundError('Usuário'));
    }

    return right(toLoginResponse(user));
  }
}
