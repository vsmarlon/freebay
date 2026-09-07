import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CursorPage, clampLimit, decodeIdCursor } from '@/shared/core/pagination';
import { ModerationRepository } from '../domain/repositories/moderation.repository';
import { ModerationActionRow } from '../types/admin.types';

@Injectable()
export class ListModerationActionsUseCase {
  constructor(private readonly moderationRepository: ModerationRepository) {}

  async execute(input: {
    cursor?: string;
    limit?: number;
  }): Promise<Either<AppError, CursorPage<ModerationActionRow>>> {
    const result = await this.moderationRepository.findActions({
      cursorId: decodeIdCursor(input.cursor),
      limit: clampLimit(input.limit),
    });
    if (isLeft(result)) return left(result.value);

    return right(result.value);
  }
}
