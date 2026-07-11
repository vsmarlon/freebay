import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { StartConversationOutput } from '../dtos/chat.dto';

@Injectable()
export class StartConversationUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly blockRepository: BlockRepository,
  ) {}

  async execute(initiatorId: string, targetUserId: string): Promise<Either<AppError, StartConversationOutput>> {
    if (initiatorId === targetUserId) {
      return left(new BadRequestError('Cannot start conversation with yourself'));
    }

    const userResult = await this.conversationRepository.findUserById(targetUserId);
    if (isLeft(userResult)) return left(userResult.value);
    if (!userResult.value) return left(new NotFoundError('User'));

    const [isBlockedResult, isBlockedByOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(initiatorId, targetUserId),
      this.blockRepository.isBlocked(targetUserId, initiatorId),
    ]);
    if (isBlockedResult.isLeft()) return left(isBlockedResult.value);
    if (isBlockedByOtherResult.isLeft()) return left(isBlockedByOtherResult.value);
    if (isBlockedResult.value) return left(new ForbiddenError('Você bloqueou este usuário'));
    if (isBlockedByOtherResult.value) return left(new ForbiddenError('Você foi bloqueado por este usuário'));

    const existingResult = await this.conversationRepository.findDirectConversationBetweenUsers(initiatorId, targetUserId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (existingResult.value) {
      return right({ conversationId: existingResult.value.id, status: existingResult.value.status });
    }

    const followResult = await this.conversationRepository.findFollow(initiatorId, targetUserId);
    if (isLeft(followResult)) return left(followResult.value);

    const status = followResult.value ? 'ACTIVE' : 'PENDING';

    const createResult = await this.conversationRepository.createDirectConversation({
      user1: { connect: { id: initiatorId } },
      user2: { connect: { id: targetUserId } },
      status,
    });
    if (isLeft(createResult)) return left(createResult.value);

    return right({ conversationId: createResult.value.id, status });
  }
}
