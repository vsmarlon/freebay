import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';
import { Prisma, DirectMessage, ChatMessage, MessageType } from '@prisma/client';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly blockRepository: BlockRepository,
    private readonly ogScraper: OgScraperService,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const resolved = await this.threadAccess.resolveThread(input.senderId, input.conversationId);
    if (isLeft(resolved)) return left(resolved.value);

    if (resolved.value.orderId) {
      return this.sendOrderMessage(input, resolved.value.orderId, resolved.value.otherUserId);
    }

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

    const blockCheck = await this.assertNotBlocked(input.senderId, otherUserId);
    if (blockCheck) return left(blockCheck);

    const messageType = (input.type ?? 'TEXT') as MessageType;

    const productCardError = this.assertProductCardMetadata(messageType, input);
    if (productCardError) return left(productCardError);

    const metadata = await this.buildMetadata(messageType, input);

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: input.conversationId } },
      sender: { connect: { id: input.senderId } },
      content: input.content ?? null,
      type: messageType,
      attachmentUrl: input.attachmentUrl ?? null,
      metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
      replyTo: input.replyToId ? { connect: { id: input.replyToId } } : undefined,
      viewOnce: input.viewOnce ?? false,
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
      viewOnce: msg.viewOnce,
      createdAt: msg.createdAt,
    });
  }

  private async sendOrderMessage(
    input: SendMessageInput,
    orderId: string,
    otherUserId: string,
  ): Promise<Either<AppError, SendMessageOutput>> {
    const blockCheck = await this.assertNotBlocked(input.senderId, otherUserId);
    if (blockCheck) return left(blockCheck);

    const messageType = (input.type ?? 'TEXT') as MessageType;

    const productCardError = this.assertProductCardMetadata(messageType, input);
    if (productCardError) return left(productCardError);

    const metadata = await this.buildMetadata(messageType, input);

    const messageResult = await this.conversationRepository.createChatMessage({
      order: { connect: { id: orderId } },
      sender: { connect: { id: input.senderId } },
      content: input.content ?? null,
      type: messageType,
      attachmentUrl: input.attachmentUrl ?? null,
      metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
      replyTo: input.replyToId ? { connect: { id: input.replyToId } } : undefined,
      viewOnce: input.viewOnce ?? false,
    }, true);
    if (isLeft(messageResult)) return left(messageResult.value);

    const msg = messageResult.value as ChatMessage;
    return right({
      id: msg.id,
      conversationId: orderId,
      senderId: msg.senderId,
      content: msg.content ?? null,
      type: msg.type,
      attachmentUrl: msg.attachmentUrl ?? null,
      metadata: (msg.metadata as Record<string, unknown>) ?? null,
      replyToId: msg.replyToId ?? null,
      viewOnce: msg.viewOnce,
      createdAt: msg.createdAt,
    });
  }

  private async assertNotBlocked(senderId: string, otherUserId: string): Promise<AppError | null> {
    const [isBlockedResult, isBlockedByOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(senderId, otherUserId),
      this.blockRepository.isBlocked(otherUserId, senderId),
    ]);
    if (isBlockedResult.isLeft()) return isBlockedResult.value;
    if (isBlockedByOtherResult.isLeft()) return isBlockedByOtherResult.value;
    if (isBlockedResult.value) return new ForbiddenError('Você bloqueou este usuário');
    if (isBlockedByOtherResult.value) return new ForbiddenError('Você foi bloqueado por este usuário');
    return null;
  }

  private assertProductCardMetadata(messageType: MessageType, input: SendMessageInput): AppError | null {
    if (messageType !== 'PRODUCT_CARD') return null;
    const productId = input.metadata?.productId;
    if (!productId || typeof productId !== 'string' || productId.trim().length === 0) {
      return new BadRequestError('Product ID is required for product cards');
    }
    return null;
  }

  private async buildMetadata(
    messageType: MessageType,
    input: SendMessageInput,
  ): Promise<Record<string, unknown> | null> {
    if (messageType !== 'TEXT' || !input.content) return input.metadata ?? null;

    const url = this.ogScraper.extractFirstUrl(input.content);
    if (!url) return input.metadata ?? null;

    const og = await this.ogScraper.scrape(url);
    return og ? (og as unknown as Record<string, unknown>) : input.metadata ?? null;
  }
}
