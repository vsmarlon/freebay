import { Injectable } from '@nestjs/common';
import { ModerationActionType } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { RepositoryResponse } from '@/shared/core/either';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';

import { ModerationTargetType } from '@prisma/client';

export type RemovableContentType = Exclude<ModerationTargetType, 'USER' | 'REPORT'>;

const ACTION_BY_TYPE: Record<RemovableContentType, ModerationActionType> = {
  PRODUCT: 'PRODUCT_REMOVED',
  POST: 'POST_REMOVED',
  COMMENT: 'COMMENT_REMOVED',
};

const LABEL_BY_TYPE: Record<RemovableContentType, string> = {
  PRODUCT: 'Produto',
  POST: 'Publicação',
  COMMENT: 'Comentário',
};

@Injectable()
export class RemoveContentUseCase {
  constructor(private readonly moderationRepository: ModerationDatabaseRepository) {}

  async execute(input: {
    targetType: RemovableContentType;
    targetId: string;
    adminId: string;
    reason?: string;
  }): Promise<Either<AppError, void>> {
    const removeResult = await this.remove(input.targetType, input.targetId);
    if (removeResult.isLeft()) return left(removeResult.value);
    if (removeResult.value.count === 0) {
      return left(new NotFoundError(LABEL_BY_TYPE[input.targetType]));
    }

    const actionResult = await this.moderationRepository.recordAction({
      actorId: input.adminId,
      targetType: input.targetType,
      targetId: input.targetId,
      action: ACTION_BY_TYPE[input.targetType],
      reason: input.reason ?? null,
    });
    if (actionResult.isLeft()) return left(actionResult.value);

    return right(undefined);
  }

  private remove(
    targetType: RemovableContentType,
    targetId: string,
  ): RepositoryResponse<{ count: number }> {
    if (targetType === ModerationTargetType.PRODUCT) {
      return this.moderationRepository.softDeleteProduct(targetId);
    }
    if (targetType === ModerationTargetType.POST) {
      return this.moderationRepository.softDeletePost(targetId);
    }
    return this.moderationRepository.softDeleteComment(targetId);
  }
}
