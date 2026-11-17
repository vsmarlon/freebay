import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ConflictError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { AcceptConversationOutput } from '../dtos/chat.dto';
import { canAcceptDirect } from '../domain/conversation-state';

@Injectable()
export class AcceptConversationUseCase {
  constructor(private readonly conversationRepository: ConversationDatabaseRepository) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, AcceptConversationOutput>> {
    const convResult = await this.conversationRepository.findDirectConversationById(conversationId);
    if (convResult.isLeft()) return left(convResult.value);
    const conversation = convResult.value;

    if (!conversation) return left(new NotFoundError('Conversation'));
    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized'));
    }
    if (!canAcceptDirect({
      status: conversation.status,
      userId,
      initiatorId: conversation.initiatorId ?? null,
    })) {
      return left(new BadRequestError('Conversation is not pending or you are the initiator'));
    }

    const accepted = await this.conversationRepository.acceptDirectConversation(conversationId);
    if (accepted.isLeft()) return left(accepted.value);
    if (!accepted.value) return left(new ConflictError('Conversation changed before acceptance'));

    return right({ accepted: true });
  }
}
