import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaConversationPreferenceRepository } from '../repositories/conversation-preference.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class ArchiveConversationUseCase {
  constructor(
    private prisma: PrismaService,
    private preferenceRepo: PrismaConversationPreferenceRepository,
  ) {}

  async execute(
    userId: string,
    conversationId: string,
    archived: boolean,
  ): Promise<Either<AppError, ConversationPreference>> {
    let orderId: string | undefined;
    let directConversationId: string | undefined;

    const directConv = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (directConv) {
      if (directConv.user1Id !== userId && directConv.user2Id !== userId) {
        return left(new ForbiddenError('Você não é participante desta conversa'));
      }
      directConversationId = conversationId;
    } else {
      const order = await this.prisma.order.findUnique({
        where: { id: conversationId },
      });

      if (!order) {
        return left(new NotFoundError('Conversa'));
      }

      if (order.buyerId !== userId && order.sellerId !== userId) {
        return left(new ForbiddenError('Você não é participante desta conversa'));
      }

      if (archived && order.status !== 'COMPLETED' && order.status !== 'CANCELLED') {
        return left(new ForbiddenError('Só é possível arquivar após o pedido ser concluído ou cancelado'));
      }

      orderId = conversationId;
    }

    const updated = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      isArchived: archived,
    });

    return right(updated);
  }
}
