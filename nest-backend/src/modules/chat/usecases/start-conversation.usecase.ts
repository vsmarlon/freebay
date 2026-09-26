import { Injectable } from '@nestjs/common';
import { ConversationStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { StartConversationOutput } from '../dtos/chat.dto';
import { toStartConversationOutput } from '../mappers/conversation.mapper';

@Injectable()
export class StartConversationUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly blockRepository: PrismaBlockRepository,
  ) {}

  async execute(initiatorId: string, targetUserId: string, productId?: string): Promise<Either<AppError, StartConversationOutput>> {
    if (initiatorId === targetUserId) {
      return left(new BadRequestError('Cannot start conversation with yourself'));
    }

    const userResult = await this.conversationRepository.findUserById(targetUserId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new NotFoundError('User'));

    if (productId) {
      const productResult = await this.conversationRepository.findProductSummary(productId);
      if (productResult.isLeft()) return left(productResult.value);
      if (!productResult.value) return left(new NotFoundError('Product'));
      if (productResult.value.sellerId !== targetUserId) {
        return left(new BadRequestError('Product does not belong to target user'));
      }
    }

    const [isBlockedResult, isBlockedByOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(initiatorId, targetUserId),
      this.blockRepository.isBlocked(targetUserId, initiatorId),
    ]);
    if (isBlockedResult.isLeft()) return left(isBlockedResult.value);
    if (isBlockedByOtherResult.isLeft()) return left(isBlockedByOtherResult.value);
    if (isBlockedResult.value) return left(new ForbiddenError('Você bloqueou este usuário'));
    if (isBlockedByOtherResult.value) return left(new ForbiddenError('Você foi bloqueado por este usuário'));

    const [user1Id, user2Id] = initiatorId < targetUserId
      ? [initiatorId, targetUserId]
      : [targetUserId, initiatorId];

    const existingResult = productId
      ? await this.conversationRepository.findProductConversationBetweenUsers(user1Id, user2Id, productId)
      : await this.conversationRepository.findDirectConversationBetweenUsers(user1Id, user2Id);
    if (existingResult.isLeft()) return left(existingResult.value);
    if (existingResult.value) {
      return right(toStartConversationOutput(existingResult.value, userResult.value));
    }

    const followResult = await this.conversationRepository.findFollow(initiatorId, targetUserId);
    if (followResult.isLeft()) return left(followResult.value);

    const status = followResult.value ? ConversationStatus.ACTIVE : ConversationStatus.PENDING;

    const createResult = await this.conversationRepository.createDirectConversation({
      user1: { connect: { id: user1Id } },
      user2: { connect: { id: user2Id } },
      ...(productId ? { product: { connect: { id: productId } } } : {}),
      scopeKey: productId ? `PRODUCT:${productId}` : 'DIRECT',
      status,
    });
    if (createResult.isLeft()) return left(createResult.value);

    return right(toStartConversationOutput(createResult.value, userResult.value));
  }
}
