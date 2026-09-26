import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { SendMessageInput, SendMessageInternalOutput, SendMessageOutput } from '../dtos/chat.dto';
import { Prisma, DirectMessage, ChatMessage, MessageType, ChatThreadType } from '@prisma/client';
import { DirectMessageWithSender, ChatMessageWithSender } from '../mappers/conversation.mapper';
import {
  readCanonicalLocationMetadata,
  validateLocationMetadata,
} from './location-message-metadata';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly blockRepository: PrismaBlockRepository,
    private readonly ogScraper: OgScraperService,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageInternalOutput>> {
    const resolved = await this.threadAccess.resolveThread(input.senderId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    if (resolved.value.orderId) {
      return this.runMessagePipeline(input, {
        threadId: resolved.value.orderId,
        otherUserId: resolved.value.otherUserId,
        model: ChatThreadType.ORDER,
        isOrder: true,
      });
    }

    return this.runMessagePipeline(input, {
      threadId: input.conversationId,
      otherUserId: resolved.value.otherUserId,
      model: ChatThreadType.DIRECT,
      isOrder: false,
    });
  }

  // ponytail: single shared pipeline for direct/order sends; only persistence branches.
  private async runMessagePipeline(
    input: SendMessageInput,
    ctx: { threadId: string; otherUserId: string; model: ChatThreadType; isOrder: boolean },
  ): Promise<Either<AppError, SendMessageInternalOutput>> {
    const blockCheck = await this.assertNotBlocked(input.senderId, ctx.otherUserId);
    if (blockCheck) return left(blockCheck);

    const messageType = input.type ?? MessageType.TEXT;

    const locationMetadata = validateLocationMetadata(messageType, input.metadata);
    if (locationMetadata.isLeft()) return left(locationMetadata.value);
    const existingLocation = await this.findDelayedLocationRetry(
      messageType,
      locationMetadata.value,
      ctx.threadId,
      input.senderId,
      ctx.isOrder,
      input.clientMessageId,
      ctx.otherUserId,
    );
    if (existingLocation) return existingLocation;

    const productCardError = this.assertProductCardMetadata(messageType, input);
    if (productCardError) return left(productCardError);

    const metadata = await this.buildMetadata(messageType, input, locationMetadata.value);

    const replyScope = await this.assertReplyInThread(
      input.replyToId,
      ctx.threadId,
      ctx.model,
    );
    if (replyScope) return left(replyScope);

    if (ctx.isOrder) {
      const messageResult = await this.conversationRepository.createChatMessage({
        order: { connect: { id: ctx.threadId } },
        sender: { connect: { id: input.senderId } },
        clientMessageId: input.clientMessageId ?? null,
        content: input.content ?? null,
        type: messageType,
        attachmentUrl: input.attachmentUrl ?? null,
        metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
        replyTo: input.replyToId ? { connect: { id: input.replyToId } } : undefined,
        viewOnce: input.viewOnce ?? false,
      }, true);
      if (messageResult.isLeft()) return left(messageResult.value);
      return right(this.toInternalOutput(messageResult.value, ctx.threadId, ctx.otherUserId));
    }

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: ctx.threadId } },
      sender: { connect: { id: input.senderId } },
      clientMessageId: input.clientMessageId ?? null,
      content: input.content ?? null,
      type: messageType,
      attachmentUrl: input.attachmentUrl ?? null,
      metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
      replyTo: input.replyToId ? { connect: { id: input.replyToId } } : undefined,
      viewOnce: input.viewOnce ?? false,
    }, true);
    if (messageResult.isLeft()) return left(messageResult.value);

    const updateResult = await this.conversationRepository.updateDirectConversation(ctx.threadId, {
      lastMessageAt: new Date(),
    });
    if (updateResult.isLeft()) return left(updateResult.value);

    const msg = messageResult.value;
    return right(this.toInternalOutput(msg, msg.conversationId, ctx.otherUserId));
  }

  private async assertReplyInThread(
    replyToId: string | undefined,
    threadId: string,
    model: ChatThreadType,
  ): Promise<AppError | null> {
    if (!replyToId) return null;
    const belongs = await this.conversationRepository.messageBelongsToThread(
      replyToId,
      threadId,
      model,
    );
    if (belongs.isLeft()) return belongs.value;
    if (!belongs.value) return new NotFoundError('Mensagem referenciada');
    return null;
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

  private async findDelayedLocationRetry(
    messageType: MessageType,
    metadata: Record<string, unknown> | null,
    threadId: string,
    senderId: string,
    isOrder: boolean,
    clientMessageId?: string,
    recipientId = '',
  ): Promise<Either<AppError, SendMessageInternalOutput> | null> {
    if (
      messageType !== 'LOCATION' ||
      !metadata ||
      typeof metadata.capturedAt !== 'string'
    ) return null;

    const capturedAt = new Date(metadata.capturedAt);
    const now = Date.now();
    const isFresh = capturedAt.getTime() >= now - 5 * 60 * 1000 &&
        capturedAt.getTime() <= now + 60 * 1000;
    if (isFresh) return null;
    if (!clientMessageId) return left(new BadRequestError('Data da localização expirada'));

    const existing = isOrder
        ? await this.conversationRepository.findChatMessageByClientId(
            threadId,
            senderId,
            clientMessageId,
          )
        : await this.conversationRepository.findDirectMessageByClientId(
            threadId,
            senderId,
            clientMessageId,
          );
    if (existing.isLeft()) return left(existing.value);
    if (!existing.value) return left(new BadRequestError('Data da localização expirada'));
    const existingMetadata = readCanonicalLocationMetadata(existing.value.metadata);
    const metadataMatches = existing.value.type === MessageType.LOCATION &&
      existingMetadata !== null &&
      existingMetadata.latitude === metadata.latitude &&
      existingMetadata.longitude === metadata.longitude &&
      existingMetadata.accuracyMeters === metadata.accuracyMeters &&
      existingMetadata.capturedAt === metadata.capturedAt &&
      (existingMetadata.address ?? null) === (metadata.address ?? null);
    if (!metadataMatches) {
      return left(new BadRequestError('Conflito de idempotência da localização'));
    }
    return right(this.toInternalOutput(existing.value, threadId, recipientId));
  }

  private toInternalOutput(
    message: DirectMessage | ChatMessage | DirectMessageWithSender | ChatMessageWithSender,
    conversationId: string,
    recipientId: string,
  ): SendMessageInternalOutput {
    return {
      message: this.toMessageOutput(message, conversationId),
      recipientId,
      senderName: 'sender' in message && message.sender ? message.sender.displayName || 'Alguém' : 'Alguém',
    };
  }

  private toMessageOutput(
    message: DirectMessage | ChatMessage,
    conversationId: string,
  ): SendMessageOutput {
    return {
      id: message.id,
      conversationId,
      senderId: message.senderId,
      clientMessageId: message.clientMessageId ?? null,
      content: message.content ?? null,
      type: message.type,
      attachmentUrl: message.attachmentUrl ?? null,
      metadata: (message.metadata as Record<string, unknown>) ?? null,
      replyToId: message.replyToId ?? null,
      viewOnce: message.viewOnce,
      createdAt: message.createdAt,
    };
  }

  private async buildMetadata(
    messageType: MessageType,
    input: SendMessageInput,
    validatedLocationMetadata: Record<string, unknown> | null,
  ): Promise<Record<string, unknown> | null> {
    let base: Record<string, unknown> | null = messageType === MessageType.LOCATION
      ? validatedLocationMetadata
      : input.metadata ?? null;

    if (messageType === MessageType.TEXT && input.content) {
      const url = this.ogScraper.extractFirstUrl(input.content);
      if (url) {
        const og = await this.ogScraper.scrape(url);
        base = og ? { ...og } : base;
      }
    }

    if (input.durationMs != null && messageType !== 'LOCATION') {
      base = { ...(base ?? {}), durationMs: input.durationMs };
    }

    return base;
  }
}
