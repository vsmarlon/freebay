import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';

@Injectable()
export class MarkAsReadUseCase {
  constructor(
    private readonly threadAccess: ChatThreadAccessService,
    private readonly conversationRepository: ConversationDatabaseRepository,
  ) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, void>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const { orderId, directConversationId } = resolved.value;

    if (orderId) {
      return this.conversationRepository.markChatMessagesRead(orderId, userId);
    }

    if (directConversationId) {
      return this.conversationRepository.markMessagesRead(directConversationId, userId);
    }

    return right(undefined);
  }
}
