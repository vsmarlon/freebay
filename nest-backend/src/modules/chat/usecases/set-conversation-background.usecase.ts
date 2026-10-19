import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { isOwnedUpload } from '@/shared/utils/file.utils';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationPreferenceDatabaseRepository } from '../data/repositories/conversation-preference-database.repository';
import { ConversationPreference } from '@prisma/client';

@Injectable()
export class SetConversationBackgroundUseCase {
  constructor(
    private threadAccess: ChatThreadAccessService,
    private preferenceRepo: ConversationPreferenceDatabaseRepository,
  ) {}

  async execute(
    userId: string,
    conversationId: string,
    background: string,
  ): Promise<Either<AppError, ConversationPreference>> {
    if (!isOwnedUpload(background, userId, 'background')) {
      return left(new BadRequestError('Fundo inválido ou não pertence ao usuário'));
    }
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) {
      return left(resolved.value);
    }

    const { orderId, directConversationId } = resolved.value;

    const result = await this.preferenceRepo.upsert({
      userId,
      orderId,
      directConversationId,
      backgroundUrl: background,
    });
    if (result.isLeft()) return left(result.value);

    return right(result.value);
  }
}
