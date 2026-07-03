import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { GetMessagesOutput } from '../dtos/chat.dto';

@Injectable()
export class GetMessagesUseCase {
  constructor(private readonly conversationRepository: ConversationRepository) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, GetMessagesOutput[]>> {
    const convResult = await this.conversationRepository.findDirectConversationById(conversationId);
    if (isLeft(convResult)) return left(convResult.value);
    const conversation = convResult.value;

    if (!conversation) return left(new NotFoundError('Conversation'));
    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized to view this conversation'));
    }

    const msgsResult = await this.conversationRepository.findMessagesByConversation(conversationId);
    if (isLeft(msgsResult)) return left(msgsResult.value);

    const readResult = await this.conversationRepository.markMessagesRead(conversationId, userId);
    if (isLeft(readResult)) return left(readResult.value);

    const result: GetMessagesOutput[] = msgsResult.value.map(msg => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? '',
      type: msg.type,
      readAt: msg.readAt,
      deliveredAt: msg.deliveredAt,
      createdAt: msg.createdAt,
    }));

    return right(result);
  }
}
