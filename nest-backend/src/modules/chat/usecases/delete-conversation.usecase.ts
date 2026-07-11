import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ForbiddenError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationPreferenceRepository } from '../domain/repositories/conversation-preference.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class DeleteConversationUseCase {
  constructor(
    private threadAccess: ChatThreadAccessService,
    private preferenceRepo: ConversationPreferenceRepository,
  ) {}

  async execute(
    userId: string,
    conversationId: string,
  ): Promise<Either<AppError, ConversationPreference>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) {
      return left(resolved.value);
    }

    const { orderId, directConversationId, orderStatus } = resolved.value;

    if (orderId && orderStatus !== 'COMPLETED' && orderStatus !== 'CANCELLED') {
      return left(new ForbiddenError('Só é possível excluir após o pedido ser concluído ou cancelado'));
    }

    const result = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      isDeleted: true,
    });
    if (result.isLeft()) return left(result.value);

    return right(result.value);
  }
}
