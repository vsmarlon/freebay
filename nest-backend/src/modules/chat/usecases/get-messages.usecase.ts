import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { ConversationPreferenceRepository } from '../domain/repositories/conversation-preference.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { GetMessagesOutput, GetMessagesResult } from '../dtos/chat.dto';
import {
  ChatMessageWithSender,
  DirectMessageWithSender,
} from '../mappers/conversation.mapper';

@Injectable()
export class GetMessagesUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly preferenceRepository: ConversationPreferenceRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(conversationId: string, userId: string): Promise<Either<AppError, GetMessagesResult>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (isLeft(resolved)) return left(resolved.value);

    const { orderId, directConversationId, otherUserId } = resolved.value;
    const isOrderThread = Boolean(orderId);

    const messages: GetMessagesOutput[] = [];

    if (isOrderThread) {
      const msgsResult = await this.conversationRepository.findChatMessagesByOrder(orderId!);
      if (isLeft(msgsResult)) return left(msgsResult.value);

      const readResult = await this.conversationRepository.markChatMessagesRead(orderId!, userId);
      if (isLeft(readResult)) return left(readResult.value);

      messages.push(...msgsResult.value.map((msg) => this.toOutput(msg, conversationId)));
    } else {
      const msgsResult = await this.conversationRepository.findMessagesByConversation(directConversationId!);
      if (isLeft(msgsResult)) return left(msgsResult.value);

      const readResult = await this.conversationRepository.markMessagesRead(directConversationId!, userId);
      if (isLeft(readResult)) return left(readResult.value);

      messages.push(...msgsResult.value.map((msg) => this.toOutput(msg, conversationId)));
    }

    const preferenceResult = await this.preferenceRepository.findByAnyId(userId, conversationId);
    if (isLeft(preferenceResult)) return left(preferenceResult.value);
    const preference = preferenceResult.value;

    return right({
      messages,
      threadType: isOrderThread ? 'ORDER' : 'DIRECT',
      otherUserId,
      preference: preference
        ? {
            isArchived: preference.isArchived,
            theme: preference.theme,
            backgroundUrl: preference.backgroundUrl,
          }
        : null,
    });
  }

  private toOutput(
    msg: DirectMessageWithSender | ChatMessageWithSender,
    conversationId: string,
  ): GetMessagesOutput {
    return {
      id: msg.id,
      conversationId,
      senderId: msg.senderId,
      content: msg.content ?? null,
      type: msg.type,
      attachmentUrl: msg.attachmentUrl ?? null,
      metadata: (msg.metadata as Record<string, unknown>) ?? null,
      replyToId: msg.replyToId ?? null,
      replyTo: msg.replyTo
        ? {
            id: msg.replyTo.id,
            senderId: msg.replyTo.senderId,
            content: msg.replyTo.deletedAt ? null : msg.replyTo.content,
            type: msg.replyTo.type,
            attachmentUrl: msg.replyTo.deletedAt ? null : msg.replyTo.attachmentUrl,
            deletedAt: msg.replyTo.deletedAt,
          }
        : null,
      deletedAt: msg.deletedAt ?? null,
      readAt: msg.readAt,
      deliveredAt: msg.deliveredAt,
      createdAt: msg.createdAt,
    };
  }
}
