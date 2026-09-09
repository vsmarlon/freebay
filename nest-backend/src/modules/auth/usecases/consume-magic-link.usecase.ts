import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, InvalidTokenError } from '@/shared/core/errors';
import { ConsumeMagicLinkDTO } from '../dtos/magic-link.dto';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

@Injectable()
export class ConsumeMagicLinkUseCase {
  constructor(private readonly repository: MagicLinkRepository) {}

  async execute(input: ConsumeMagicLinkDTO): Promise<Either<AppError, AuthResponse>> {
    const tokenHash = createHash('sha256').update(input.token).digest('hex');
    const consumed = await this.repository.consume(tokenHash, new Date());
    if (consumed.isLeft()) return left(consumed.value);
    if (!consumed.value) return left(new InvalidTokenError('Link inválido ou expirado'));
    return right(toAuthResponse(consumed.value));
  }
}
