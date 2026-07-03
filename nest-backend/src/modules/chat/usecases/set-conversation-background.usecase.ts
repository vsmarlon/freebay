import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { PrismaConversationPreferenceRepository } from '../repositories/conversation-preference.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class SetConversationBackgroundUseCase {
  constructor(
    private threadAccess: ChatThreadAccessService,
    private preferenceRepo: PrismaConversationPreferenceRepository,
  ) {}

  async execute(
    userId: string,
    conversationId: string,
    background: string,
  ): Promise<Either<AppError, ConversationPreference>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) {
      return left(resolved.value);
    }

    const { orderId, directConversationId } = resolved.value;

    const updated = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      backgroundUrl: background,
    });

    return right(updated);
  }
}
