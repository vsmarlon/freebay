import { Injectable } from '@nestjs/common';
import { ChatTheme } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationPreferenceRepository } from '../domain/repositories/conversation-preference.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class SetConversationThemeUseCase {
  constructor(
    private threadAccess: ChatThreadAccessService,
    private preferenceRepo: ConversationPreferenceRepository,
  ) {}

  async execute(
    userId: string,
    conversationId: string,
    theme?: string,
  ): Promise<Either<AppError, ConversationPreference>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) {
      return left(resolved.value);
    }

    const { orderId, directConversationId } = resolved.value;

    const result = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      theme: theme as ChatTheme,
    });
    if (result.isLeft()) return left(result.value);

    return right(result.value);
  }
}
