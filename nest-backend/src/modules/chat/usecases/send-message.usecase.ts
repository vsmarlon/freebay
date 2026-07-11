import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';
import { Prisma, DirectMessage, MessageType } from '@prisma/client';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly blockRepository: BlockRepository,
    private readonly ogScraper: OgScraperService,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const conversationResult = await this.conversationRepository.findDirectConversationById(input.conversationId);
    if (isLeft(conversationResult)) return left(conversationResult.value);
    const conversation = conversationResult.value;

    if (!conversation) return left(new NotFoundError('Conversation'));

    if (conversation.status === 'PENDING') {
      const isParticipant = conversation.user1Id === input.senderId || conversation.user2Id === input.senderId;
      if (!isParticipant) return left(new BadRequestError('Conversation is pending acceptance'));
    }

    const otherUserId = conversation.user1Id === input.senderId
      ? conversation.user2Id
      : conversation.user1Id;

    const [isBlockedResult, isBlockedByOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(input.senderId, otherUserId),
      this.blockRepository.isBlocked(otherUserId, input.senderId),
    ]);
    if (isBlockedResult.isLeft()) return left(isBlockedResult.value);
    if (isBlockedByOtherResult.isLeft()) return left(isBlockedByOtherResult.value);
    if (isBlockedResult.value) return left(new ForbiddenError('Você bloqueou este usuário'));
    if (isBlockedByOtherResult.value) return left(new ForbiddenError('Você foi bloqueado por este usuário'));

    const messageType = (input.type ?? 'TEXT') as MessageType;
    let metadata: Record<string, unknown> | null = input.metadata ?? null;

    if (messageType === 'TEXT' && input.content) {
      const url = this.ogScraper.extractFirstUrl(input.content);
      if (url) {
        const og = await this.ogScraper.scrape(url);
        if (og) metadata = og as unknown as Record<string, unknown>;
      }
    }

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: input.conversationId } },
      sender: { connect: { id: input.senderId } },
      content: input.content ?? null,
      type: messageType,
      attachmentUrl: input.attachmentUrl ?? null,
      metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
      replyTo: input.replyToId ? { connect: { id: input.replyToId } } : undefined,
    }, true);
    if (isLeft(messageResult)) return left(messageResult.value);

    const updateResult = await this.conversationRepository.updateDirectConversation(input.conversationId, {
      lastMessageAt: new Date(),
    });
    if (isLeft(updateResult)) return left(updateResult.value);

    const msg = messageResult.value as DirectMessage;
    return right({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? null,
      type: msg.type,
      attachmentUrl: msg.attachmentUrl ?? null,
      metadata: (msg.metadata as Record<string, unknown>) ?? null,
      replyToId: msg.replyToId ?? null,
      createdAt: msg.createdAt,
    });
  }
}
