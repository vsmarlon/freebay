import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ForwardMessagesInput, ForwardMessagesOutput, SendMessageOutput } from '../dtos/chat.dto';
import { Prisma, MessageType } from '@prisma/client';

@Injectable()
export class ForwardMessagesUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly conversationRepository: ConversationDatabaseRepository,
    private readonly blockRepository: PrismaBlockRepository,
    private readonly threadAccess: ChatThreadAccessService,
  ) {}

  async execute(input: ForwardMessagesInput): Promise<Either<AppError, ForwardMessagesOutput>> {
    if (!input.messageIds || input.messageIds.length === 0) {
      return left(new BadRequestError('Nenhuma mensagem selecionada para encaminhamento'));
    }

    if (!input.targetConversationIds || input.targetConversationIds.length === 0) {
      return left(new BadRequestError('Nenhum destinatário selecionado para encaminhamento'));
    }

    const [directMsgs, orderMsgs] = await Promise.all([
      this.prisma.directMessage.findMany({
        where: { id: { in: input.messageIds }, deletedAt: null },
        include: { sender: { select: { displayName: true } } },
      }),
      this.prisma.chatMessage.findMany({
        where: { id: { in: input.messageIds }, deletedAt: null },
        include: { sender: { select: { displayName: true } } },
      }),
    ]);

    type SourceMsg = {
      id: string;
      content: string | null;
      type: MessageType;
      attachmentUrl: string | null;
      metadata: Prisma.JsonValue;
      sender: { displayName: string } | null;
      viewOnce: boolean;
      readAt: Date | null;
      sourceThreadId: string;
    };

    const allSourceMsgs: SourceMsg[] = [
      ...directMsgs.map((m) => ({ ...m, sourceThreadId: m.conversationId })),
      ...orderMsgs.map((m) => ({ ...m, sourceThreadId: m.orderId })),
    ];
    if (allSourceMsgs.length === 0) {
      return left(new NotFoundError('Mensagens para encaminhamento'));
    }

    for (const sourceMsg of allSourceMsgs) {
      const sourceThread = await this.threadAccess.resolveThread(
        input.userId,
        sourceMsg.sourceThreadId,
      );
      if (sourceThread.isLeft()) {
        return left(new ForbiddenError('Você não participa da conversa de origem'));
      }

      if (sourceMsg.viewOnce) {
        return left(
          new ForbiddenError('Mensagens de visualização única não podem ser encaminhadas'),
        );
      }
    }


    const sortedMessages: SourceMsg[] = [];
    for (const id of input.messageIds) {
      const found = allSourceMsgs.find((m) => m.id === id);
      if (found) sortedMessages.push(found);
    }

    const createdOutputs: SendMessageOutput[] = [];


    for (const targetConvId of input.targetConversationIds) {
      const threadRes = await this.threadAccess.resolveThread(input.userId, targetConvId);
      if (threadRes.isLeft()) {
        return left(threadRes.value);
      }

      const thread = threadRes.value;
      const blockCheck = await this.assertNotBlocked(input.userId, thread.otherUserId);
      if (blockCheck) return left(blockCheck);

      for (const sourceMsg of sortedMessages) {
        const originalMetadata = (sourceMsg.metadata as Record<string, unknown>) ?? {};
        const forwardedMetadata: Record<string, unknown> = {
          ...originalMetadata,
          isForwarded: true,
          forwardedFrom: sourceMsg.sender?.displayName ?? 'Usuário',
        };

        if (thread.directConversationId) {
          const createRes = await this.conversationRepository.createDirectMessage({
            conversation: { connect: { id: thread.directConversationId } },
            sender: { connect: { id: input.userId } },
            content: sourceMsg.content,
            type: sourceMsg.type,
            attachmentUrl: sourceMsg.attachmentUrl,
            metadata: forwardedMetadata as Prisma.InputJsonValue,
            viewOnce: false,
          }, true);

          if (createRes.isLeft()) return left(createRes.value);

          await this.conversationRepository.updateDirectConversation(thread.directConversationId, {
            lastMessageAt: new Date(),
          });

          const msg = createRes.value;
          createdOutputs.push({
            id: msg.id,
            conversationId: thread.directConversationId,
            senderId: input.userId,
            clientMessageId: null,
            content: msg.content ?? null,
            type: msg.type,
            attachmentUrl: msg.attachmentUrl ?? null,
            metadata: forwardedMetadata,
            replyToId: null,
            viewOnce: false,
            createdAt: msg.createdAt,
          });
        } else if (thread.orderId) {
          const createRes = await this.conversationRepository.createChatMessage({
            order: { connect: { id: thread.orderId } },
            sender: { connect: { id: input.userId } },
            content: sourceMsg.content,
            type: sourceMsg.type,
            attachmentUrl: sourceMsg.attachmentUrl,
            metadata: forwardedMetadata as Prisma.InputJsonValue,
            viewOnce: false,
          }, true);

          if (createRes.isLeft()) return left(createRes.value);

          const msg = createRes.value;
          createdOutputs.push({
            id: msg.id,
            conversationId: thread.orderId,
            senderId: input.userId,
            clientMessageId: null,
            content: msg.content ?? null,
            type: msg.type,
            attachmentUrl: msg.attachmentUrl ?? null,
            metadata: forwardedMetadata,
            replyToId: null,
            viewOnce: false,
            createdAt: msg.createdAt,
          });
        }
      }
    }

    return right({
      forwardedCount: createdOutputs.length,
      messages: createdOutputs,
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
}
