import { User } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AccountSuspendedError, AppError } from '@/shared/core/errors';
import { SessionTokenService } from '../services/session-token.service';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { toUserResponse } from '../../users/dtos/user-response.class';

export function issueSession(user: User, tokens: SessionTokenService): Either<AppError, AuthSessionResponse> {
  if (user.suspendedAt) return left(new AccountSuspendedError(user.suspensionReason));
  return right({ user: toUserResponse(user, undefined, true), ...tokens.generate(user.id, user.role) });
}
