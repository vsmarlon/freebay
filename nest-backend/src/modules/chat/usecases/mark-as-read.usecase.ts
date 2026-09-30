import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ChatThreadType } from '@prisma/client';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';

@Injectable()
export class MarkAsReadUseCase {
  constructor(
    private readonly threadAccess: ChatThreadAccessService,
    private readonly conversationRepository: ConversationDatabaseRepository,
  ) {}

  async execute(conversationId: string, userId: string, messageId?: string): Promise<Either<AppError, void>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const { orderId, directConversationId } = resolved.value;
    if (messageId) {
      const belongs = await this.conversationRepository.messageBelongsToThread(messageId, orderId ?? directConversationId ?? conversationId, orderId ? ChatThreadType.ORDER : ChatThreadType.DIRECT);
      if (belongs.isLeft()) return left(belongs.value);
      if (!belongs.value) return left(new NotFoundError('Mensagem'));
    }

    if (orderId) {
      return messageId ? this.conversationRepository.markChatMessagesRead(orderId, userId, messageId) : this.conversationRepository.markChatMessagesRead(orderId, userId);
    }

    if (directConversationId) {
      return messageId ? this.conversationRepository.markMessagesRead(directConversationId, userId, messageId) : this.conversationRepository.markMessagesRead(directConversationId, userId);
    }

    return right(undefined);
  }
}
