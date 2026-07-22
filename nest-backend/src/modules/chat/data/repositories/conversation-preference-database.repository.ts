import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ChatThreadType, ConversationPreference } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { ConversationPreferenceRepository, UpsertPreferenceInput } from '../../domain/repositories/conversation-preference.repository';

@Injectable()
export class PrismaConversationPreferenceRepository implements ConversationPreferenceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByAnyId(userId: string, threadId: string): RepositoryResponse<ConversationPreference | null> {
    try {
      return right(
        await this.prisma.conversationPreference.findFirst({
          where: {
            userId,
            OR: [
              { directConversationId: threadId },
              { orderId: threadId },
            ],
          },
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find preference'));
    }
  }

  async findByUserAndThread(userId: string, threadId: string, type: ChatThreadType): RepositoryResponse<ConversationPreference | null> {
    try {
      const where = type === 'DIRECT'
        ? { userId_directConversationId: { userId, directConversationId: threadId } }
        : { userId_orderId: { userId, orderId: threadId } };
      return right(await this.prisma.conversationPreference.findUnique({ where }));
    } catch {
      return left(new DatabaseError('Failed to find preference'));
    }
  }

  async upsert(input: UpsertPreferenceInput): RepositoryResponse<ConversationPreference> {
    const hasDirect = !!input.directConversationId;
    const hasOrder = !!input.orderId;

    if (hasDirect === hasOrder) {
      return left(new BadRequestError('Exactly one of orderId or directConversationId must be set'));
    }

    const where = hasDirect
      ? { userId_directConversationId: { userId: input.userId, directConversationId: input.directConversationId! } }
      : { userId_orderId: { userId: input.userId, orderId: input.orderId! } };

    try {
      return right(
        await this.prisma.conversationPreference.upsert({
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
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to upsert preference'));
    }
  }

  async findArchived(userId: string): RepositoryResponse<ConversationPreference[]> {
    try {
      return right(
        await this.prisma.conversationPreference.findMany({
          where: { userId, isArchived: true, isDeleted: false },
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find archived preferences'));
    }
  }

  async findDeleted(userId: string): RepositoryResponse<ConversationPreference[]> {
    try {
      return right(
        await this.prisma.conversationPreference.findMany({
          where: { userId, isDeleted: true },
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find deleted preferences'));
    }
  }
}
