import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ChatThreadType } from '@prisma/client';

const VALID_EMOJIS = ['❤️', '😂', '😮', '😢', '😡', '👍'];

export interface ReactionSummary {
  emoji: string;
  count: number;
  userIds: string[];
}

@Injectable()
export class ToggleReactionUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: {
    userId: string;
    messageId: string;
    emoji: string;
    conversationId: string;
  }): Promise<Either<AppError, { reactions: ReactionSummary[] }>> {
    if (!VALID_EMOJIS.includes(input.emoji)) {
      return left(new BadRequestError(`Emoji inválido. Permitidos: ${VALID_EMOJIS.join(' ')}`));
    }

    const resolved = await this.threadAccess.resolveThread(input.userId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const messageModel = resolved.value.orderId
      ? ChatThreadType.ORDER
      : ChatThreadType.DIRECT;

    const existing = await this.conversationRepository.findReactionByUserAndMessage(
      input.userId, input.messageId, messageModel,
    );
    if (existing.isLeft()) return left(existing.value);

    if (existing.value && existing.value.emoji === input.emoji) {
      const del = await this.conversationRepository.deleteReaction(existing.value.id);
      if (del.isLeft()) return left(del.value);
    } else {
      const upsert = await this.conversationRepository.upsertReaction({
        userId: input.userId,
        messageId: input.messageId,
        emoji: input.emoji,
        model: messageModel,
      });
      if (upsert.isLeft()) return left(upsert.value);
    }

    const allResult = await this.conversationRepository.getReactionsForMessage(input.messageId, messageModel);
    if (allResult.isLeft()) return left(allResult.value);

    const grouped = VALID_EMOJIS.reduce<ReactionSummary[]>((acc, emoji) => {
      const matching = allResult.value.filter((r) => r.emoji === emoji);
      if (matching.length > 0) {
        acc.push({ emoji, count: matching.length, userIds: matching.map((r) => r.userId) });
      }
      return acc;
    }, []);

    return right({ reactions: grouped });
  }
}
