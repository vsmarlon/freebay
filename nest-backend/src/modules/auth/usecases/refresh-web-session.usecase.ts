import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AccountSuspendedError, AppError, InvalidTokenError, UserNotFoundError } from '@/shared/core/errors';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { SessionTokenService } from '../services/session-token.service';

@Injectable()
export class RefreshWebSessionUseCase {
  constructor(
    private readonly users: UserDatabaseRepository,
    private readonly tokens: SessionTokenService,
  ) {}

  async execute(payload: JwtPayload): Promise<Either<AppError, { token: string; refreshToken: string }>> {
    if (payload.type !== JwtTokenType.REFRESH || !payload.userId) return left(new InvalidTokenError());
    const user = await this.users.findById(payload.userId);
    if (user.isLeft()) return left(user.value);
    if (!user.value) return left(new UserNotFoundError());
    if (user.value.suspendedAt) return left(new AccountSuspendedError(user.value.suspensionReason));
    if (!payload.jti || !payload.exp) return left(new InvalidTokenError());
    if (!await this.tokens.claimRefresh(payload.jti, payload.exp)) return left(new InvalidTokenError('Sessão já renovada'));
    const generated = this.tokens.generate(user.value.id, user.value.role);
    return right({ token: generated.token, refreshToken: generated.refreshToken });
  }
}
