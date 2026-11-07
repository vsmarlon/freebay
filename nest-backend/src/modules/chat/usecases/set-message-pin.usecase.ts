import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';

@Injectable()
export class SetMessagePinUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: { userId: string; conversationId: string; messageId: string; pinned: boolean }): Promise<Either<AppError, { pinned: boolean }>> {
    const resolved = await this.threadAccess.resolveThread(input.userId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);
    const result = await this.conversationRepository.setMessagePinned(
      input.messageId,
      input.conversationId,
      resolved.value.orderId ? 'ORDER' : 'DIRECT',
      input.pinned,
      input.userId,
    );
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new NotFoundError('Mensagem'));
    return right({ pinned: input.pinned });
  }
}
