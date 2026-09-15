import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { OgScraperService } from '../services/og-scraper.service';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';
import { Prisma, DirectMessage, ChatMessage, MessageType, ChatThreadType } from '@prisma/client';

type CanonicalLocationMetadata = {
  latitude: number;
  longitude: number;
  accuracyMeters: number;
  capturedAt: string;
  address?: string;
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const readCanonicalLocationMetadata = (value: unknown): CanonicalLocationMetadata | null => {
  if (!isRecord(value)) return null;
  const keys = new Set(['latitude', 'longitude', 'accuracyMeters', 'capturedAt', 'address']);
  if (Object.keys(value).some((key) => !keys.has(key))) return null;
  if (
    typeof value.latitude !== 'number' ||
    typeof value.longitude !== 'number' ||
    typeof value.accuracyMeters !== 'number' ||
    typeof value.capturedAt !== 'string'
  ) return null;
  if (value.address != null && typeof value.address !== 'string') return null;
  return {
    latitude: value.latitude,
    longitude: value.longitude,
    accuracyMeters: value.accuracyMeters,
    capturedAt: value.capturedAt,
    ...(typeof value.address === 'string' ? { address: value.address } : {}),
  };
};

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly blockRepository: PrismaBlockRepository,
    private readonly ogScraper: OgScraperService,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const resolved = await this.threadAccess.resolveThread(input.senderId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    if (resolved.value.orderId) {
      return this.sendOrderMessage(input, resolved.value.orderId, resolved.value.otherUserId);
    }

    const conversationResult = await this.conversationRepository.findDirectConversationById(input.conversationId);
    if (conversationResult.isLeft()) return left(conversationResult.value);
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

    const locationMetadata = this.validateLocationMetadata(messageType, input.metadata);
    if (locationMetadata.isLeft()) return left(locationMetadata.value);
    const existingLocation = await this.findDelayedLocationRetry(
      messageType,
      locationMetadata.value,
      input.conversationId,
      input.senderId,
      false,
      input.clientMessageId,
    );
    if (existingLocation) return existingLocation;

    const productCardError = this.assertProductCardMetadata(messageType, input);
    if (productCardError) return left(productCardError);

    const metadata = await this.buildMetadata(messageType, input, locationMetadata.value);

    const replyScope = await this.assertReplyInThread(
      input.replyToId,
      input.conversationId,
      ChatThreadType.DIRECT,
    );
    if (replyScope) return left(replyScope);

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: input.conversationId } },
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

    const updateResult = await this.conversationRepository.updateDirectConversation(input.conversationId, {
      lastMessageAt: new Date(),
    });
    if (updateResult.isLeft()) return left(updateResult.value);

    const msg = messageResult.value as DirectMessage;
    return right({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      clientMessageId: msg.clientMessageId ?? null,
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

    const locationMetadata = this.validateLocationMetadata(messageType, input.metadata);
    if (locationMetadata.isLeft()) return left(locationMetadata.value);
    const existingLocation = await this.findDelayedLocationRetry(
      messageType,
      locationMetadata.value,
      orderId,
      input.senderId,
      true,
      input.clientMessageId,
    );
    if (existingLocation) return existingLocation;

    const productCardError = this.assertProductCardMetadata(messageType, input);
    if (productCardError) return left(productCardError);

    const metadata = await this.buildMetadata(messageType, input, locationMetadata.value);

    const replyScope = await this.assertReplyInThread(
      input.replyToId,
      orderId,
      ChatThreadType.ORDER,
    );
    if (replyScope) return left(replyScope);

    const messageResult = await this.conversationRepository.createChatMessage({
      order: { connect: { id: orderId } },
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

    const msg = messageResult.value as ChatMessage;
    return right({
      id: msg.id,
      conversationId: orderId,
      senderId: msg.senderId,
      clientMessageId: msg.clientMessageId ?? null,
      content: msg.content ?? null,
      type: msg.type,
      attachmentUrl: msg.attachmentUrl ?? null,
      metadata: (msg.metadata as Record<string, unknown>) ?? null,
      replyToId: msg.replyToId ?? null,
      viewOnce: msg.viewOnce,
      createdAt: msg.createdAt,
    });
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
  ): Promise<Either<AppError, SendMessageOutput> | null> {
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
    const metadataMatches = existing.value.type === 'LOCATION' &&
      existingMetadata !== null &&
      existingMetadata.latitude === metadata.latitude &&
      existingMetadata.longitude === metadata.longitude &&
      existingMetadata.accuracyMeters === metadata.accuracyMeters &&
      existingMetadata.capturedAt === metadata.capturedAt &&
      (existingMetadata.address ?? null) === (metadata.address ?? null);
    if (!metadataMatches) {
      return left(new BadRequestError('Conflito de idempotência da localização'));
    }
    return right(this.toMessageOutput(existing.value, threadId));
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

  private validateLocationMetadata(
    messageType: MessageType,
    metadata: Record<string, unknown> | undefined,
  ): Either<AppError, Record<string, unknown> | null> {
    if (messageType !== 'LOCATION') return right(null);
    if (!metadata) return left(new BadRequestError('Metadados de localização são obrigatórios'));

    const allowedKeys = new Set(['latitude', 'longitude', 'accuracyMeters', 'capturedAt', 'address']);
    if (Object.keys(metadata).some((key) => !allowedKeys.has(key))) {
      return left(new BadRequestError('Metadados de localização inválidos'));
    }

    const latitude = metadata.latitude;
    const longitude = metadata.longitude;
    const accuracyMeters = metadata.accuracyMeters;
    const capturedAt = metadata.capturedAt;
    const isFiniteNumber = (value: unknown): value is number =>
      typeof value === 'number' && Number.isFinite(value);

    if (!isFiniteNumber(latitude) || latitude < -90 || latitude > 90) {
      return left(new BadRequestError('Latitude inválida'));
    }
    if (!isFiniteNumber(longitude) || longitude < -180 || longitude > 180) {
      return left(new BadRequestError('Longitude inválida'));
    }
    if (!isFiniteNumber(accuracyMeters) || accuracyMeters < 0 || accuracyMeters > 100_000) {
      return left(new BadRequestError('Precisão da localização inválida'));
    }
    const canonicalTimestamp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
    const parsedTimestamp = typeof capturedAt === 'string' ? new Date(capturedAt) : null;
    if (
      typeof capturedAt !== 'string' ||
      !canonicalTimestamp.test(capturedAt) ||
      parsedTimestamp === null ||
      !Number.isFinite(parsedTimestamp.getTime()) ||
      parsedTimestamp.toISOString() !== capturedAt
    ) {
      return left(new BadRequestError('Data da localização inválida'));
    }
    if (
      metadata.address != null &&
      (typeof metadata.address !== 'string' ||
        metadata.address.trim().length === 0 ||
        metadata.address.length > 500)
    ) {
      return left(new BadRequestError('Endereço da localização inválido'));
    }
    return right({
      latitude,
      longitude,
      accuracyMeters,
      capturedAt,
      ...(typeof metadata.address === 'string'
        ? { address: metadata.address.trim() }
        : {}),
    });
  }

  private async buildMetadata(
    messageType: MessageType,
    input: SendMessageInput,
    validatedLocationMetadata: Record<string, unknown> | null,
  ): Promise<Record<string, unknown> | null> {
    let base: Record<string, unknown> | null = messageType === 'LOCATION'
      ? validatedLocationMetadata
      : input.metadata ?? null;

    if (messageType === 'TEXT' && input.content) {
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
