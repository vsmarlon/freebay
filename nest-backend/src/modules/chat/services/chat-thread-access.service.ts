import { Injectable } from '@nestjs/common';
import { AppError, NotFoundError, BadRequestError, ForbiddenError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ChatThreadTypeParam } from '../dtos/chat.dto';

const TERMINAL_ORDER_STATUSES = ['COMPLETED', 'CANCELLED'];

@Injectable()
export class ChatThreadAccessService {
  constructor(private prisma: PrismaService) {}

  async verifyParticipant(
    userId: string,
    threadId: string,
    threadType: ChatThreadTypeParam,
  ): Promise<AppError | null> {
    if (threadType === 'DIRECT') {
      const conv = await this.prisma.directConversation.findUnique({ where: { id: threadId } });
      if (!conv) return new NotFoundError('Conversa');
      if (conv.user1Id !== userId && conv.user2Id !== userId) {
        return new BadRequestError('Not a participant of this conversation');
      }
      return null;
    }

    const order = await this.prisma.order.findUnique({ where: { id: threadId } });
    if (!order) return new NotFoundError('Pedido');
    if (order.buyerId !== userId && order.sellerId !== userId) {
      return new BadRequestError('Not a participant of this order');
    }
    return null;
  }

  async verifyParticipantAndTerminal(
    userId: string,
    threadId: string,
    threadType: ChatThreadTypeParam,
  ): Promise<AppError | null> {
    if (threadType === 'DIRECT') {
      return this.verifyParticipant(userId, threadId, threadType);
    }

    const order = await this.prisma.order.findUnique({ where: { id: threadId } });
    if (!order) return new NotFoundError('Pedido');
    if (order.buyerId !== userId && order.sellerId !== userId) {
      return new BadRequestError('Not a participant of this order');
    }
    if (!TERMINAL_ORDER_STATUSES.includes(order.status)) {
      return new ForbiddenError('Disponível apenas após o pedido ser concluído ou cancelado');
    }
    return null;
  }

  async resolveOtherUserId(
    threadId: string,
    threadType: ChatThreadTypeParam,
    userId: string,
  ): Promise<string | null> {
    if (threadType === 'DIRECT') {
      const conv = await this.prisma.directConversation.findUnique({ where: { id: threadId } });
      if (!conv) return null;
      return conv.user1Id === userId ? conv.user2Id : conv.user1Id;
    }

    const order = await this.prisma.order.findUnique({ where: { id: threadId } });
    if (!order) return null;
    return order.buyerId === userId ? order.sellerId : order.buyerId;
  }
}
