import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { MessageType } from '@prisma/client';
import {
  GetMessagesOutput,
  GetFilteredMessagesInput,
  GetFilteredMessagesResult,
  FILTERED_MESSAGES_DEFAULT_LIMIT,
} from '../dtos/chat.dto';
import {
  ChatMessageWithSender,
  DirectMessageWithSender,
} from '../mappers/conversation.mapper';

@Injectable()
export class GetConversationMediaUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(
    input: GetFilteredMessagesInput,
  ): Promise<Either<AppError, GetFilteredMessagesResult>> {
    const resolved = await this.threadAccess.resolveThread(input.userId, input.conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const { orderId, directConversationId } = resolved.value;
    const isOrderThread = Boolean(orderId);
    const type = input.type ?? MessageType.IMAGE;
    const limit = input.limit ?? FILTERED_MESSAGES_DEFAULT_LIMIT;

    let allMessages: (DirectMessageWithSender | ChatMessageWithSender)[];

    if (isOrderThread) {
      const result = await this.conversationRepository.findChatMessagesByType(
        orderId!,
        type,
        limit,
        input.cursor,
      );
      if (result.isLeft()) return left(result.value);
      allMessages = result.value;
    } else {
      const result = await this.conversationRepository.findDirectMessagesByType(
        directConversationId!,
        type,
        limit,
        input.cursor,
      );
      if (result.isLeft()) return left(result.value);
      allMessages = result.value;
    }

    const hasMore = allMessages.length > limit;
    const messages = hasMore ? allMessages.slice(0, limit) : allMessages;
    const nextCursor = hasMore ? messages[messages.length - 1].id : null;

    return right({
      messages: messages.map((msg) => this.toOutput(msg, input.conversationId)),
      nextCursor,
    });
  }

  private toOutput(
    msg: DirectMessageWithSender | ChatMessageWithSender,
    conversationId: string,
  ): GetMessagesOutput {
    const isViewOnceHidden = msg.viewOnce && msg.readAt !== null;

    function replyContent(
      reply: NonNullable<DirectMessageWithSender['replyTo'] | ChatMessageWithSender['replyTo']>,
    ): string | null {
      if (reply.deletedAt) return null;
      if (reply.viewOnce && reply.readAt !== null) return null;
      return reply.content;
    }

    return {
      id: msg.id,
      conversationId,
      senderId: msg.senderId,
      content: isViewOnceHidden ? null : (msg.content ?? null),
      type: msg.type,
      attachmentUrl: isViewOnceHidden ? null : (msg.attachmentUrl ?? null),
      metadata: isViewOnceHidden ? null : ((msg.metadata as Record<string, unknown>) ?? null),
      replyToId: msg.replyToId ?? null,
      replyTo: msg.replyTo
        ? {
            id: msg.replyTo.id,
            senderId: msg.replyTo.senderId,
            content: replyContent(msg.replyTo),
            type: msg.replyTo.type,
            attachmentUrl: msg.replyTo.viewOnce && msg.replyTo.readAt !== null ? null : (msg.replyTo.attachmentUrl ?? null),
            deletedAt: msg.replyTo.deletedAt,
            conversationId,
            createdAt: msg.replyTo.createdAt,
            viewOnce: msg.replyTo.viewOnce,
            readAt: msg.replyTo.readAt,
          }
        : null,
      deletedAt: msg.deletedAt ?? null,
      readAt: msg.readAt,
      deliveredAt: msg.deliveredAt,
      createdAt: msg.createdAt,
      viewOnce: msg.viewOnce,
    };
  }
}
