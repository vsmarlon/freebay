import { Injectable } from '@nestjs/common';
import { ChatThreadType } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { GetMessagesOutput } from '../dtos/chat.dto';
import { redactReplySummary } from '../dtos/conversation-response';
import {
  ChatMessageWithSender,
  DirectMessageWithSender,
} from '../data/repositories/conversation/payloads';

@Injectable()
export class GetStarredMessagesUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(
    conversationId: string,
    userId: string,
  ): Promise<Either<AppError, GetMessagesOutput[]>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const threadId = resolved.value.orderId ?? resolved.value.directConversationId!;
    const messageModel = resolved.value.orderId ? ChatThreadType.ORDER : ChatThreadType.DIRECT;

    const starsResult = await this.conversationRepository.findStarredMessages(
      userId,
      threadId,
      messageModel,
    );
    if (starsResult.isLeft()) return left(starsResult.value);

    return right(starsResult.value.map((msg) => this.toOutput(msg, conversationId)));
  }

  private toOutput(
    msg: DirectMessageWithSender | ChatMessageWithSender,
    conversationId: string,
  ): GetMessagesOutput {
    const isViewOnceHidden = msg.viewOnce && msg.readAt !== null;
    const replyTo = msg.replyTo ? redactReplySummary(msg.replyTo) : null;

    return {
      id: msg.id,
      conversationId,
      senderId: msg.senderId,
      content: isViewOnceHidden ? null : (msg.content ?? null),
      type: msg.type,
      attachmentUrl: isViewOnceHidden ? null : (msg.attachmentUrl ?? null),
      metadata: isViewOnceHidden ? null : ((msg.metadata as Record<string, unknown>) ?? null),
      replyToId: msg.replyToId ?? null,
      replyTo: replyTo
        ? {
            id: replyTo.id,
            senderId: replyTo.senderId,
            content: replyTo.content,
            type: replyTo.type,
            attachmentUrl: replyTo.attachmentUrl,
            deletedAt: replyTo.deletedAt,
            conversationId,
            createdAt: replyTo.createdAt,
            viewOnce: replyTo.viewOnce,
            readAt: replyTo.readAt,
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
