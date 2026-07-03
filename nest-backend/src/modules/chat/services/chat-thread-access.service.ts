import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

export interface ResolvedChatThread {
  orderId?: string;
  directConversationId?: string;
  otherUserId: string;
  orderStatus?: string;
}

@Injectable()
export class ChatThreadAccessService {
  constructor(private prisma: PrismaService) {}

  async resolveThread(
    userId: string,
    conversationId: string,
  ): Promise<Either<AppError, ResolvedChatThread>> {
    const directConv = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (directConv) {
      if (directConv.user1Id !== userId && directConv.user2Id !== userId) {
        return left(new ForbiddenError('Você não é participante desta conversa'));
      }
      const otherUserId = directConv.user1Id === userId ? directConv.user2Id : directConv.user1Id;
      return right({ directConversationId: conversationId, otherUserId });
    }

    const order = await this.prisma.order.findUnique({ where: { id: conversationId } });
    if (!order) {
      return left(new NotFoundError('Conversa'));
    }
    if (order.buyerId !== userId && order.sellerId !== userId) {
      return left(new ForbiddenError('Você não é participante desta conversa'));
    }
    const otherUserId = order.buyerId === userId ? order.sellerId : order.buyerId;
    return right({ orderId: conversationId, otherUserId, orderStatus: order.status });
  }
}
