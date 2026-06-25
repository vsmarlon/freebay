import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetMessagesOutput } from '../dtos/chat.dto';

@Injectable()
export class GetMessagesUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, GetMessagesOutput[]>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized to view this conversation'));
    }

    const messages = await this.prisma.directMessage.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: USER_SELECT_MINIMAL },
      },
    });

    await this.prisma.directMessage.updateMany({
      where: { conversationId, senderId: { not: userId }, readAt: null },
      data: { readAt: new Date(), deliveredAt: new Date() },
    });

    const result: GetMessagesOutput[] = messages.map(msg => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? '',
      type: msg.type,
      readAt: msg.readAt,
      deliveredAt: msg.deliveredAt,
      createdAt: msg.createdAt,
    }));

    return right(result);
  }
}
