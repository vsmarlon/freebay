import { Injectable } from '@nestjs/common';
import { ChatThreadType, ChatTheme, ConversationPreference } from '@prisma/client';
import { RepositoryResponse, left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UpsertPreferenceInput } from '../../types/chat.types';

@Injectable()
export class PrismaConversationPreferenceRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findByAnyId(userId: string, threadId: string): RepositoryResponse<ConversationPreference | null> {
    return repositoryResponse(
      () =>
        this.prisma.conversationPreference.findFirst({
          where: {
            userId,
            OR: [
              { directConversationId: threadId },
              { orderId: threadId },
            ],
          },
        }),
      'Failed to find preference',
    );
  }

  async findByUserAndThread(userId: string, threadId: string, type: ChatThreadType): RepositoryResponse<ConversationPreference | null> {
    const where = type === ChatThreadType.DIRECT
      ? { userId_directConversationId: { userId, directConversationId: threadId } }
      : { userId_orderId: { userId, orderId: threadId } };
    return repositoryResponse(
      () => this.prisma.conversationPreference.findUnique({ where }),
      'Failed to find preference',
    );
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

    return repositoryResponse(
      () =>
        this.prisma.conversationPreference.upsert({
          where,
          create: {
            userId: input.userId,
            orderId: input.orderId ?? null,
            directConversationId: input.directConversationId ?? null,
            isArchived: input.isArchived ?? false,
            isDeleted: input.isDeleted ?? false,
            theme: input.theme ?? ChatTheme.DEFAULT,
            backgroundUrl: input.backgroundUrl ?? null,
          },
          update: {
            isArchived: input.isArchived ?? undefined,
            isDeleted: input.isDeleted ?? undefined,
            theme: input.theme ?? undefined,
            backgroundUrl: input.backgroundUrl ?? undefined,
          },
        }),
      'Failed to upsert preference',
    );
  }

  async findArchived(userId: string): RepositoryResponse<ConversationPreference[]> {
    return repositoryResponse(
      () =>
        this.prisma.conversationPreference.findMany({
          where: { userId, isArchived: true, isDeleted: false },
        }),
      'Failed to find archived preferences',
    );
  }

  async findDeleted(userId: string): RepositoryResponse<ConversationPreference[]> {
    return repositoryResponse(
      () => this.prisma.conversationPreference.findMany({
        where: { userId, isDeleted: true },
      }),
      'Failed to find deleted preferences',
    );
  }
}
