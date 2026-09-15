import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PrismaSavedPostRepository } from '../data/repositories/saved-post-database.repository';
import { SavedPostsCursor } from '../types/social.types';
import { CursorPage } from '@/shared/core/pagination';
import { PostResponse } from '../types/social.types';

@Injectable()
export class GetSavedPostsUseCase {
  constructor(private readonly savedPostRepository: PrismaSavedPostRepository) {}

  async execute(input: { userId: string; limit?: number; cursor?: string }): Promise<Either<AppError, CursorPage<PostResponse>>> {
    const cursor = parseCursor(input.cursor, input.userId);
    if (cursor.isLeft()) return left(cursor.value);
    const result = await this.savedPostRepository.findSaved({ ...input, cursor: cursor.value });
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}

function parseCursor(
  rawCursor: string | undefined,
  userId: string,
): Either<AppError, SavedPostsCursor | undefined> {
  if (!rawCursor) return right(undefined);
  try {
    const parsed: unknown = JSON.parse(Buffer.from(rawCursor, 'base64url').toString('utf8'));
    if (!isSavedPostsCursor(parsed)) return left(new BadRequestError('Cursor inválido'));
    if (parsed.scope !== 'saved-posts' || parsed.userId !== userId) {
      return left(new BadRequestError('Cursor não pertence a esta lista'));
    }
    if (Number.isNaN(new Date(parsed.createdAt).getTime())) {
      return left(new BadRequestError('Cursor inválido'));
    }
    return right(parsed);
  } catch {
    return left(new BadRequestError('Cursor inválido'));
  }
}

function isSavedPostsCursor(value: unknown): value is SavedPostsCursor {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  const payload: Record<string, unknown> = Object.fromEntries(Object.entries(value));
  return typeof payload.scope === 'string' &&
    typeof payload.userId === 'string' &&
    typeof payload.createdAt === 'string' &&
    typeof payload.savedPostId === 'string' &&
    payload.userId.length > 0 && payload.savedPostId.length > 0;
}
