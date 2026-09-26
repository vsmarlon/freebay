import { User } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AccountSuspendedError, AppError } from '@/shared/core/errors';
import { SessionTokenService } from '../services/session-token.service';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

export type AuthSession = AuthResponse & { token: string; refreshToken: string };

export function issueSession(user: User, tokens: SessionTokenService): Either<AppError, AuthSession> {
  if (user.suspendedAt) return left(new AccountSuspendedError(user.suspensionReason));
  return right({ user: toAuthResponse(user).user, ...tokens.generate(user.id, user.role) });
}
