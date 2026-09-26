import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidCredentialsError, NotFoundError, SessionExpiredError, UnauthorizedError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { LoginResponse } from '../mappers/auth.mapper';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';

export type BiometricLoginOutput = {
  user: LoginResponse['user'];
  token: string;
  refreshToken: string;
  biometricToken: string;
};

@Injectable()
export class BiometricLoginUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(biometricToken: string): Promise<Either<AppError, BiometricLoginOutput>> {
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
    if (!payload.jti || !payload.exp) return left(new InvalidCredentialsError());
    const blacklisted = await this.redisService.get(`blacklist:${payload.jti}`);
    if (blacklisted) {
      return left(new InvalidCredentialsError());
    }
    const claimed = await this.redisService.get(`biometric-claimed:${payload.jti}`);
    if (claimed) {
      return left(new InvalidCredentialsError());
    }

    // 4. Check global invalidation cutoff (e.g. password reset)
    if (payload.userId && payload.iat) {
      const invalidBefore = await this.redisService.get(`user_tokens_invalid_before:${payload.userId}`);
      if (invalidBefore && payload.iat < Number(invalidBefore)) {
        return left(new SessionExpiredError());
      }
    }

    // 5. Look up the user
    const userResult = await this.userRepository.findById(payload.userId!);
    if (userResult.isLeft()) return left(userResult.value);
    const user = userResult.value;

    if (!user) {
      return left(new NotFoundError('Usuário'));
    }
    if (!await this.sessionTokens.claimBiometric(payload.jti, payload.exp)) {
      return left(new UnauthorizedError('Token biométrico inválido ou já utilizado'));
    }
    const session = issueSession(user, this.sessionTokens);
    if (session.isLeft()) return left(session.value);
    return right({ ...session.value, biometricToken: this.sessionTokens.generateBiometric(user.id, user.role) });
  }
}
