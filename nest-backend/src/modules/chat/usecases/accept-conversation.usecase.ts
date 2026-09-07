import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { AcceptConversationOutput } from '../dtos/chat.dto';

@Injectable()
export class AcceptConversationUseCase {
  constructor(private readonly conversationRepository: ConversationDatabaseRepository) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, AcceptConversationOutput>> {
    const convResult = await this.conversationRepository.findDirectConversationById(conversationId);
    if (isLeft(convResult)) return left(convResult.value);
    const conversation = convResult.value;

    if (!conversation) return left(new NotFoundError('Conversation'));
    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized'));
    }
    if (conversation.status !== 'PENDING') {
      return left(new BadRequestError('Conversation is not pending'));
    }

    const updateResult = await this.conversationRepository.updateDirectConversation(conversationId, {
      status: 'ACTIVE',
    });
    if (isLeft(updateResult)) return left(updateResult.value);

    return right({ accepted: true });
  }
}
