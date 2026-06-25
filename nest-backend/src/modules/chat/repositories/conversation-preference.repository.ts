import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ChatTheme } from '@prisma/client';

export interface UpsertPreferenceInput {
  userId: string;
  orderId?: string;
  directConversationId?: string;
  isArchived?: boolean;
  isDeleted?: boolean;
  theme?: ChatTheme;
  backgroundUrl?: string | null;
}

@Injectable()
export class PrismaConversationPreferenceRepository {
  constructor(private prisma: PrismaService) {}

  async findByAnyId(userId: string, threadId: string) {
    return this.prisma.conversationPreference.findFirst({
      where: {
        userId,
        OR: [
          { directConversationId: threadId },
          { orderId: threadId },
        ],
      },
    });
  }

  async findByUserAndThread(
    userId: string,
    threadId: string,
    type: 'DIRECT' | 'ORDER',
  ) {
    const where = type === 'DIRECT'
      ? { userId_directConversationId: { userId, directConversationId: threadId } }
      : { userId_orderId: { userId, orderId: threadId } };

    return this.prisma.conversationPreference.findUnique({ where });
  }

  async upsert(input: UpsertPreferenceInput) {
    const hasDirect = !!input.directConversationId;
    const hasOrder = !!input.orderId;

    if (hasDirect === hasOrder) {
      throw new Error('Exactly one of orderId or directConversationId must be set');
    }

    const where = hasDirect
      ? { userId_directConversationId: { userId: input.userId, directConversationId: input.directConversationId! } }
      : { userId_orderId: { userId: input.userId, orderId: input.orderId! } };

    return this.prisma.conversationPreference.upsert({
      where,
      create: {
        userId: input.userId,
        orderId: input.orderId ?? null,
        directConversationId: input.directConversationId ?? null,
        isArchived: input.isArchived ?? false,
        isDeleted: input.isDeleted ?? false,
        theme: input.theme ?? 'DEFAULT',
        backgroundUrl: input.backgroundUrl ?? null,
      },
      update: {
        isArchived: input.isArchived ?? undefined,
        isDeleted: input.isDeleted ?? undefined,
        theme: input.theme ?? undefined,
        backgroundUrl: input.backgroundUrl ?? undefined,
      },
    });
  }

  async findArchived(userId: string) {
    return this.prisma.conversationPreference.findMany({
      where: { userId, isArchived: true, isDeleted: false },
    });
  }

  async findDeleted(userId: string) {
    return this.prisma.conversationPreference.findMany({
      where: { userId, isDeleted: true },
    });
  }
}
