import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { CursorPage, FIRST_PAGE, PageQuery } from '@/shared/core/pagination';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaConversationPreferenceRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ChatThreadType } from '@prisma/client';
import { GetMessagesOutput, GetMessagesResult } from '../dtos/chat.dto';
import {
  ChatMessageWithSender,
  DirectMessageWithSender,
} from '../mappers/conversation.mapper';

@Injectable()
export class GetMessagesUseCase {
  constructor(
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly preferenceRepository: PrismaConversationPreferenceRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(
    conversationId: string,
    userId: string,
    query: PageQuery = FIRST_PAGE,
  ): Promise<Either<AppError, GetMessagesResult>> {
    const resolved = await this.threadAccess.resolveThread(userId, conversationId);
    if (resolved.isLeft()) return left(resolved.value);

    const { orderId, directConversationId, otherUserId } = resolved.value;
    const isOrderThread = Boolean(orderId);

    const messages: GetMessagesOutput[] = [];
    let page: CursorPage<DirectMessageWithSender | ChatMessageWithSender>;

    if (isOrderThread) {
      const msgsResult = await this.conversationRepository.findChatMessagesByOrder(orderId!, query);
      if (msgsResult.isLeft()) return left(msgsResult.value);

      const readResult = await this.conversationRepository.markChatMessagesRead(orderId!, userId);
      if (readResult.isLeft()) return left(readResult.value);

      page = msgsResult.value;
    } else {
      const msgsResult = await this.conversationRepository.findMessagesByConversation(
        directConversationId!,
        query,
      );
      if (msgsResult.isLeft()) return left(msgsResult.value);

      const readResult = await this.conversationRepository.markMessagesRead(directConversationId!, userId);
      if (readResult.isLeft()) return left(readResult.value);

      page = msgsResult.value;
    }

    // Newest-first from the database, oldest-first for the transcript the client renders
    messages.push(
      ...[...page.items].reverse().map((msg) => this.toOutput(msg, conversationId)),
    );

    const preferenceResult = await this.preferenceRepository.findByAnyId(userId, conversationId);
    if (preferenceResult.isLeft()) return left(preferenceResult.value);
    const preference = preferenceResult.value;

    const otherUserResult = await this.conversationRepository.findUserById(otherUserId);
    if (otherUserResult.isLeft()) return left(otherUserResult.value);
    const otherUser = otherUserResult.value;
    if (!otherUser) return left(new NotFoundError('User'));

    return right({
      messages,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
      threadType: isOrderThread ? ChatThreadType.ORDER : ChatThreadType.DIRECT,
      otherUserId,
      otherUser: {
        id: otherUser.id,
        displayName: otherUser.displayName,
        avatarUrl: otherUser.avatarUrl,
      },
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
