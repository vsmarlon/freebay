import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_BASIC } from '@/shared/utils/prisma-selects';
import { ConversationWithStatus } from '../dtos/chat.dto';

@Injectable()
export class GetConversationsUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(userId: string): Promise<Either<AppError, ConversationWithStatus[]>> {
    const conversations = await this.prisma.directConversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        user1: { select: USER_SELECT_BASIC },
        user2: { select: USER_SELECT_BASIC },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    await this.prisma.directMessage.updateMany({
      where: {
        conversationId: { in: conversations.map(c => c.id) },
        senderId: { not: userId },
        deliveredAt: null,
      },
      data: { deliveredAt: new Date() },
    });

    const result: ConversationWithStatus[] = conversations.map(conv => {
      const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
      const unreadCount = conv.messages.filter(m => 
        m.senderId !== userId && !m.readAt
      ).length;
      const lastMsg = conv.messages[0];

      return {
        id: conv.id,
        otherUser,
        lastMessage: lastMsg ? {
          content: lastMsg.content ?? '',
          createdAt: lastMsg.createdAt,
        } : null,
        unreadCount,
        status: conv.status as 'ACTIVE' | 'PENDING',
        createdAt: conv.createdAt,
      };
    });

    return right(result);
  }
}
