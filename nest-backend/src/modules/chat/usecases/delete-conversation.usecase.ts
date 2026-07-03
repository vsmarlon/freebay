import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ForbiddenError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { PrismaConversationPreferenceRepository } from '../repositories/conversation-preference.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class DeleteConversationUseCase {
  constructor(
    private threadAccess: ChatThreadAccessService,
    private preferenceRepo: PrismaConversationPreferenceRepository,
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

    const updated = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      isDeleted: true,
    });

    return right(updated);
  }
}
