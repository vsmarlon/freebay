import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import {
  SendMessageInput,
  SendMessageOutput,
  ConversationWithStatus,
  StartConversationOutput,
  AcceptConversationOutput,
  GetMessagesOutput,
} from '../dtos/chat.dto';

@Injectable()
export class SendMessageUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: input.conversationId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    if (conversation.status === 'PENDING') {
      const isParticipant = conversation.user1Id === input.senderId || conversation.user2Id === input.senderId;
      if (!isParticipant) {
        return left(new BadRequestError('Conversation is pending acceptance'));
      }
    }

    const message = await this.prisma.directMessage.create({
      data: {
        conversation: { connect: { id: input.conversationId } },
        sender: { connect: { id: input.senderId } },
        content: input.content,
        type: 'TEXT',
      },
      include: {
        sender: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });

    await this.prisma.directConversation.update({
      where: { id: input.conversationId },
      data: { lastMessageAt: new Date() },
    });

    return right({
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: message.content ?? '',
      type: message.type,
      createdAt: message.createdAt,
    });
  }
}

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
        user1: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        user2: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
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
        sender: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });

    await this.prisma.directMessage.updateMany({
      where: { conversationId, senderId: { not: userId }, readAt: null },
      data: { readAt: new Date() },
    });

    const result: GetMessagesOutput[] = messages.map(msg => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? '',
      type: msg.type,
      readAt: msg.readAt,
      createdAt: msg.createdAt,
    }));

    return right(result);
  }
}

@Injectable()
export class StartConversationUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(initiatorId: string, targetUserId: string): Promise<Either<AppError, StartConversationOutput>> {
    if (initiatorId === targetUserId) {
      return left(new BadRequestError('Cannot start conversation with yourself'));
    }

    const existingConv = await this.prisma.directConversation.findFirst({
      where: {
        OR: [
          { user1Id: initiatorId, user2Id: targetUserId },
          { user1Id: targetUserId, user2Id: initiatorId },
        ],
      },
    });

    if (existingConv) {
      return right({ conversationId: existingConv.id, status: existingConv.status });
    }

    const isFollowing = await this.prisma.follow.findFirst({
      where: {
        followerId: initiatorId,
        followingId: targetUserId,
      },
    });

    const status = isFollowing ? 'ACTIVE' : 'PENDING';

    const newConv = await this.prisma.directConversation.create({
      data: {
        user1Id: initiatorId,
        user2Id: targetUserId,
        status,
      },
    });

    return right({ conversationId: newConv.id, status });
  }
}

@Injectable()
export class AcceptConversationUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, AcceptConversationOutput>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return left(new BadRequestError('Not authorized'));
    }

    if (conversation.status !== 'PENDING') {
      return left(new BadRequestError('Conversation is not pending'));
    }

    await this.prisma.directConversation.update({
      where: { id: conversationId },
      data: { status: 'ACTIVE' },
    });

    return right({ accepted: true });
  }
}
