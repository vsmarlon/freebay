import { createHash } from 'crypto';
import { Injectable } from '@nestjs/common';
import { ChatThreadType } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';

@Injectable()
export class ViewOnceUseCase {
  constructor(
    private readonly threadAccess: ChatThreadAccessService,
    private readonly conversationRepository: ConversationDatabaseRepository,
  ) {}

  async open(conversationId: string, messageId: string, userId: string, openingKey: string): Promise<Either<AppError, { messageId: string; readAt: Date; mediaUrl: string }>> {
    const thread = await this.threadAccess.resolveThread(userId, conversationId);
    if (thread.isLeft()) return left(thread.value);
    const threadId = thread.value.orderId ?? thread.value.directConversationId;
    if (!threadId) return left(new NotFoundError('Mensagem'));
    const claimed = await this.conversationRepository.claimViewOnce(
      messageId,
      threadId,
      userId,
      thread.value.orderId ? ChatThreadType.ORDER : ChatThreadType.DIRECT,
      createHash('sha256').update(openingKey).digest('hex'),
    );
    if (claimed.isLeft()) return left(claimed.value);
    if (!claimed.value) return left(new NotFoundError('Mensagem'));
    return right({ messageId, readAt: claimed.value.readAt, mediaUrl: claimed.value.attachmentUrl });
  }

  async close(conversationId: string, messageId: string, userId: string, openingKey: string): Promise<Either<AppError, void>> {
    const thread = await this.threadAccess.resolveThread(userId, conversationId);
    if (thread.isLeft()) return left(thread.value);
    const threadId = thread.value.orderId ?? thread.value.directConversationId;
    if (!threadId) return left(new NotFoundError('Mensagem'));
    const closed = await this.conversationRepository.closeViewOnce(
      messageId,
      threadId,
      userId,
      thread.value.orderId ? ChatThreadType.ORDER : ChatThreadType.DIRECT,
      createHash('sha256').update(openingKey).digest('hex'),
    );
    if (closed.isLeft()) return left(closed.value);
    if (!closed.value) return left(new NotFoundError('Mensagem'));
    return right(undefined);
  }
}
