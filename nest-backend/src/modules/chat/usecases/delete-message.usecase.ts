import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';

@Injectable()
export class DeleteMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: {
    messageId: string;
    userId: string;
    conversationId: string;
  }): Promise<Either<AppError, void>> {
    const resolved = await this.threadAccess.resolveThread(input.userId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);
    const message = await this.conversationRepository.findReplyToSummary(input.messageId);
    if (message.isLeft()) return left(message.value);
    if (!message.value || message.value.conversationId !== input.conversationId || message.value.deletedAt) return left(new NotFoundError('Mensagem'));
    if (message.value.senderId !== input.userId) return left(new ForbiddenError('Você só pode apagar suas próprias mensagens'));
    const deleteResult = await this.conversationRepository.softDeleteMessage(
      input.messageId,
      input.conversationId,
      input.userId,
      resolved.value.orderId ? 'ORDER' : 'DIRECT',
    );
    if (deleteResult.isLeft()) return left(deleteResult.value);
    if (!deleteResult.value) return left(new NotFoundError('Mensagem'));

    return right(undefined);
  }
}
