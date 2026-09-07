import { Injectable } from '@nestjs/common';
import { ModerationActionType } from '@prisma/client';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { RepositoryResponse } from '@/shared/core/either';
import { ModerationRepository } from '../domain/repositories/moderation.repository';

export type RemovableContentType = 'PRODUCT' | 'POST' | 'COMMENT';

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
  constructor(private readonly moderationRepository: ModerationRepository) {}

  async execute(input: {
    targetType: RemovableContentType;
    targetId: string;
    adminId: string;
    reason?: string;
  }): Promise<Either<AppError, void>> {
    const removeResult = await this.remove(input.targetType, input.targetId);
    if (isLeft(removeResult)) return left(removeResult.value);
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
    if (isLeft(actionResult)) return left(actionResult.value);

    return right(undefined);
  }

  private remove(
    targetType: RemovableContentType,
    targetId: string,
  ): RepositoryResponse<{ count: number }> {
    if (targetType === 'PRODUCT') {
      return this.moderationRepository.softDeleteProduct(targetId);
    }
    if (targetType === 'POST') {
      return this.moderationRepository.softDeletePost(targetId);
    }
    return this.moderationRepository.softDeleteComment(targetId);
  }
}
