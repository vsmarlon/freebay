import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ConversationWithStatus } from '../dtos/chat.dto';

@Injectable()
export class GetConversationsUseCase {
  constructor(private readonly conversationRepository: ConversationDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, ConversationWithStatus[]>> {
    const convsResult = await this.conversationRepository.findDirectConversationsByUser(userId);
    if (convsResult.isLeft()) return left(convsResult.value);

    const result: ConversationWithStatus[] = convsResult.value.map(conv => {
      const otherUser = conv.user1Id === userId ? conv.user2 : conv.user1;
      const unreadCount = (conv.messages ?? []).filter(m =>
        m.senderId !== userId && !m.readAt
      ).length;
      const lastMsg = conv.messages?.[0] ?? null;

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
