import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';

const VALID_EMOJIS = ['❤️', '😂', '😮', '😢', '😡', '👍'];

export interface ReactionSummary {
  emoji: string;
  count: number;
  userIds: string[];
}

@Injectable()
export class ToggleReactionUseCase {
  constructor(private readonly conversationRepository: ConversationRepository) {}

  async execute(input: {
    userId: string;
    messageId: string;
    emoji: string;
    messageModel: 'DIRECT' | 'ORDER';
  }): Promise<Either<AppError, { reactions: ReactionSummary[] }>> {
    if (!VALID_EMOJIS.includes(input.emoji)) {
      return left(new BadRequestError(`Emoji inválido. Permitidos: ${VALID_EMOJIS.join(' ')}`));
    }

    const existing = await this.conversationRepository.findReactionByUserAndMessage(
      input.userId, input.messageId, input.messageModel,
    );
    if (isLeft(existing)) return left(existing.value);

    if (existing.value && existing.value.emoji === input.emoji) {
      const del = await this.conversationRepository.deleteReaction(existing.value.id);
      if (isLeft(del)) return left(del.value);
    } else {
      const upsert = await this.conversationRepository.upsertReaction({
        userId: input.userId,
        messageId: input.messageId,
        emoji: input.emoji,
        model: input.messageModel,
      });
      if (isLeft(upsert)) return left(upsert.value);
    }

    const allResult = await this.conversationRepository.getReactionsForMessage(input.messageId, input.messageModel);
    if (isLeft(allResult)) return left(allResult.value);

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
