import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidTokenError } from '@/shared/core/errors';
import { ConsumeMagicLinkDTO } from '../dtos/magic-link.dto';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { SessionTokenService } from '../services/session-token.service';
import { issueSession } from '../utils/session-policy';

@Injectable()
export class ConsumeMagicLinkUseCase {
  constructor(
    private readonly repository: MagicLinkRepository,
    private readonly sessionTokens: SessionTokenService,
  ) {}

  async execute(input: ConsumeMagicLinkDTO): Promise<Either<AppError, { user: AuthSessionResponse['user']; tokens: { token: string; refreshToken: string } }>> {
    const tokenHash = createHash('sha256').update(input.token).digest('hex');
    const consumed = await this.repository.consume(tokenHash, new Date());
    if (consumed.isLeft()) return left(consumed.value);
    if (!consumed.value) return left(new InvalidTokenError('Link inválido ou expirado'));
    const session = issueSession(consumed.value, this.sessionTokens);
    if (session.isLeft()) return left(session.value);
    return right({ user: session.value.user, tokens: { token: session.value.token, refreshToken: session.value.refreshToken } });
  }
}
