import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ChatThreadType } from '@prisma/client';

@Injectable()
export class ToggleStarUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: {
    userId: string;
    messageId: string;
    conversationId: string;
  }): Promise<Either<AppError, { starred: boolean }>> {
    const resolved = await this.threadAccess.resolveThread(input.userId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const threadId = resolved.value.orderId ?? resolved.value.directConversationId!;
    const messageModel = resolved.value.orderId
      ? ChatThreadType.ORDER
      : ChatThreadType.DIRECT;

    const belongs = await this.conversationRepository.messageBelongsToThread(
      input.messageId,
      threadId,
      messageModel,
    );
    if (belongs.isLeft()) return left(belongs.value);
    if (!belongs.value) return left(new NotFoundError('Mensagem'));

    const existing = await this.conversationRepository.findStarByUserAndMessage(
      input.userId, input.messageId, messageModel,
    );
    if (existing.isLeft()) return left(existing.value);

    if (existing.value) {
      const del = await this.conversationRepository.deleteStar(existing.value.id);
      if (del.isLeft()) return left(del.value);
      return right({ starred: false });
    }

    const created = await this.conversationRepository.createStar({
      userId: input.userId,
      messageId: input.messageId,
      model: messageModel,
    });
    if (created.isLeft()) return left(created.value);
    return right({ starred: true });
  }
}
