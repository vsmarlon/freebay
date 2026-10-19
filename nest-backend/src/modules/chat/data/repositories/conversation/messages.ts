import { Prisma, DirectMessage, ChatMessage, ChatThreadType, MessageType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { CursorPage, PageQuery, paginateById } from '@/shared/core/pagination';
import { DatabaseError } from '@/shared/core/errors';
import { deleteUpload } from '@/shared/utils/file.utils';
import {
  ChatMessageWithSender,
  DirectMessageWithSender,
  ReplyToSummary,
  messageWithSenderInclude,
} from './payloads';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';

const REPLY_TO_SELECT = {
  id: true,
  senderId: true,
  content: true,
  type: true,
  attachmentUrl: true,
  deletedAt: true,
  createdAt: true,
  viewOnce: true,
  readAt: true,
} as const;

const DIRECT_MESSAGE_WITH_SENDER_ARGS = Prisma.validator<Prisma.DirectMessageDefaultArgs>()({
  include: messageWithSenderInclude,
});
const CHAT_MESSAGE_WITH_SENDER_ARGS = Prisma.validator<Prisma.ChatMessageDefaultArgs>()({
  include: messageWithSenderInclude,
});

const DIRECT_REPLY_ARGS = Prisma.validator<Prisma.DirectMessageDefaultArgs>()({
  select: { ...REPLY_TO_SELECT, conversationId: true },
});
const CHAT_REPLY_ARGS = Prisma.validator<Prisma.ChatMessageDefaultArgs>()({
  select: { ...REPLY_TO_SELECT, orderId: true },
});

export function findDirectMessageByClientId(prisma: PrismaService, conversationId: string, senderId: string, clientMessageId: string): Promise<DirectMessage | null> {
  return prisma.directMessage.findFirst({ where: { conversationId, senderId, clientMessageId } });
}

export async function createDirectMessage(prisma: PrismaService, data: Prisma.DirectMessageCreateInput, includeSender = false): RepositoryResponse<DirectMessage | DirectMessageWithSender> {
  try {
    if (includeSender) {
      const message = await prisma.directMessage.create({ data, include: { sender: { select: USER_SELECT_MINIMAL } } });
      return right(message);
    }
    const message = await prisma.directMessage.create({ data });
    return right(message);
  } catch (error) {
    const conversationId = data.conversation.connect?.id;
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002' && data.clientMessageId && conversationId && data.sender.connect?.id) {
      const existing = await prisma.directMessage.findFirst({
        where: { conversationId, senderId: data.sender.connect.id, clientMessageId: data.clientMessageId },
        ...(includeSender ? { include: { sender: { select: USER_SELECT_MINIMAL } } } : {}),
      });
      if (existing) return right(existing);
    }
    return left(new DatabaseError('Erro ao criar mensagem'));
  }
}

export function findMessagesByConversation(prisma: PrismaService, conversationId: string, page: PageQuery): Promise<CursorPage<DirectMessageWithSender>> {
  return paginateById<DirectMessageWithSender, Prisma.DirectMessageFindManyArgs>(
    (args) => prisma.directMessage.findMany({ ...args, ...DIRECT_MESSAGE_WITH_SENDER_ARGS }),
    { where: { conversationId }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], include: messageWithSenderInclude },
    page,
  );
}

export async function createChatMessage(prisma: PrismaService, data: Prisma.ChatMessageCreateInput, includeSender = false): RepositoryResponse<ChatMessage | ChatMessageWithSender> {
  try {
    if (includeSender) {
      const message = await prisma.chatMessage.create({ data, include: { sender: { select: USER_SELECT_MINIMAL } } });
      return right(message);
    }
    const message = await prisma.chatMessage.create({ data });
    return right(message);
  } catch (error) {
    const orderId = data.order.connect?.id;
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002' && data.clientMessageId && orderId && data.sender.connect?.id) {
      const existing = await prisma.chatMessage.findFirst({
        where: { orderId, senderId: data.sender.connect.id, clientMessageId: data.clientMessageId },
        ...(includeSender ? { include: { sender: { select: USER_SELECT_MINIMAL } } } : {}),
      });
      if (existing) return right(existing);
    }
    return left(new DatabaseError('Erro ao criar mensagem'));
  }
}

export function findChatMessageByClientId(prisma: PrismaService, orderId: string, senderId: string, clientMessageId: string): Promise<ChatMessage | null> {
  return prisma.chatMessage.findFirst({ where: { orderId, senderId, clientMessageId } });
}

export function findChatMessagesByOrder(prisma: PrismaService, orderId: string, page: PageQuery): Promise<CursorPage<ChatMessageWithSender>> {
  return paginateById<ChatMessageWithSender, Prisma.ChatMessageFindManyArgs>(
    (args) => prisma.chatMessage.findMany({ ...args, ...CHAT_MESSAGE_WITH_SENDER_ARGS }),
    { where: { orderId }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], include: messageWithSenderInclude },
    page,
  );
}

export function markChatMessagesRead(prisma: PrismaService, orderId: string, userId: string, messageId?: string): Promise<{ count: number }> {
  return prisma.chatMessage.updateMany({ where: { orderId, senderId: { not: userId }, readAt: null, viewOnce: false, ...(messageId ? { id: messageId } : {}) }, data: { readAt: new Date(), deliveredAt: new Date() } });
}

export function markMessagesDelivered(prisma: PrismaService, conversationId: string, userId: string): Promise<{ count: number }> {
  return prisma.directMessage.updateMany({ where: { conversationId, senderId: { not: userId }, deliveredAt: null }, data: { deliveredAt: new Date() } });
}

export function markMessagesRead(prisma: PrismaService, conversationId: string, userId: string, messageId?: string): Promise<{ count: number }> {
  return prisma.directMessage.updateMany({ where: { conversationId, senderId: { not: userId }, readAt: null, viewOnce: false, ...(messageId ? { id: messageId } : {}) }, data: { readAt: new Date(), deliveredAt: new Date() } });
}

export async function claimViewOnce(
  prisma: PrismaService,
  messageId: string,
  threadId: string,
  userId: string,
  type: ChatThreadType,
  openingHash: string,
): RepositoryResponse<{ readAt: Date; attachmentUrl: string } | null> {
  return repositoryResponse(async () => {
    const now = new Date();
    const where = type === ChatThreadType.ORDER
      ? { id: messageId, orderId: threadId, senderId: { not: userId }, viewOnce: true, deletedAt: null, attachmentUrl: { not: null } }
      : { id: messageId, conversationId: threadId, senderId: { not: userId }, viewOnce: true, deletedAt: null, attachmentUrl: { not: null } };
    const existing = type === ChatThreadType.ORDER
      ? await prisma.chatMessage.findFirst({ where, select: { readAt: true, attachmentUrl: true, viewOnceOpeningHash: true, viewOnceClosedAt: true } })
      : await prisma.directMessage.findFirst({ where, select: { readAt: true, attachmentUrl: true, viewOnceOpeningHash: true, viewOnceClosedAt: true } });
    if (existing?.viewOnceOpeningHash === openingHash && existing.viewOnceClosedAt === null && existing.readAt && existing.attachmentUrl) {
      return { readAt: existing.readAt, attachmentUrl: existing.attachmentUrl };
    }
    if (!existing || existing.readAt !== null || existing.viewOnceOpeningHash !== null || existing.viewOnceClosedAt !== null) return null;

    const claimWhere = { ...where, readAt: null, viewOnceOpeningHash: null, viewOnceClosedAt: null };
    const claimed = type === ChatThreadType.ORDER
      ? await prisma.chatMessage.updateMany({ where: claimWhere, data: { readAt: now, deliveredAt: now, viewOnceOpeningHash: openingHash } })
      : await prisma.directMessage.updateMany({ where: claimWhere, data: { readAt: now, deliveredAt: now, viewOnceOpeningHash: openingHash } });
    if (claimed.count !== 1) {
      const retry = type === ChatThreadType.ORDER
        ? await prisma.chatMessage.findFirst({ where: { ...where, viewOnceOpeningHash: openingHash, viewOnceClosedAt: null }, select: { readAt: true, attachmentUrl: true } })
        : await prisma.directMessage.findFirst({ where: { ...where, viewOnceOpeningHash: openingHash, viewOnceClosedAt: null }, select: { readAt: true, attachmentUrl: true } });
      return retry?.readAt && retry.attachmentUrl ? { readAt: retry.readAt, attachmentUrl: retry.attachmentUrl } : null;
    }

    const result = type === ChatThreadType.ORDER
      ? await prisma.chatMessage.findFirst({ where: { ...where, viewOnceOpeningHash: openingHash, viewOnceClosedAt: null }, select: { readAt: true, attachmentUrl: true } })
      : await prisma.directMessage.findFirst({ where: { ...where, viewOnceOpeningHash: openingHash, viewOnceClosedAt: null }, select: { readAt: true, attachmentUrl: true } });
    return result?.readAt && result.attachmentUrl ? { readAt: result.readAt, attachmentUrl: result.attachmentUrl } : null;
  }, 'Erro ao abrir mídia de visualização única');
}

export async function closeViewOnce(
  prisma: PrismaService,
  messageId: string,
  threadId: string,
  userId: string,
  type: ChatThreadType,
  openingHash: string,
): RepositoryResponse<boolean> {
  return repositoryResponse(async () => {
    const where = type === ChatThreadType.ORDER
      ? { id: messageId, orderId: threadId, senderId: { not: userId }, viewOnce: true, deletedAt: null, readAt: { not: null }, viewOnceOpeningHash: openingHash }
      : { id: messageId, conversationId: threadId, senderId: { not: userId }, viewOnce: true, deletedAt: null, readAt: { not: null }, viewOnceOpeningHash: openingHash };
    const changed = type === ChatThreadType.ORDER
      ? await prisma.chatMessage.updateMany({ where: { ...where, viewOnceClosedAt: null }, data: { viewOnceClosedAt: new Date() } })
      : await prisma.directMessage.updateMany({ where: { ...where, viewOnceClosedAt: null }, data: { viewOnceClosedAt: new Date() } });
    if (changed.count === 1) return true;
    const alreadyClosed = type === ChatThreadType.ORDER
      ? await prisma.chatMessage.findFirst({ where: { ...where, viewOnceClosedAt: { not: null } }, select: { id: true } })
      : await prisma.directMessage.findFirst({ where: { ...where, viewOnceClosedAt: { not: null } }, select: { id: true } });
    return alreadyClosed !== null;
  }, 'Erro ao fechar mídia de visualização única');
}

export function findDirectMessageById(prisma: PrismaService, id: string): Promise<DirectMessage | null> {
  return prisma.directMessage.findUnique({ where: { id } });
}

export async function softDeleteDirectMessage(prisma: PrismaService, id: string): Promise<void> {
  const deleted = await prisma.directMessage.update({ where: { id }, data: { deletedAt: new Date() }, select: { attachmentUrl: true } });
  deleteUpload(deleted.attachmentUrl);
}

export function findDirectMessagesByType(prisma: PrismaService, conversationId: string, type: MessageType, limit: number, cursor?: string): Promise<DirectMessageWithSender[]> {
  return prisma.directMessage.findMany({
    where: { conversationId, type }, orderBy: { createdAt: 'desc' }, take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}), ...DIRECT_MESSAGE_WITH_SENDER_ARGS,
  });
}

export function findChatMessagesByType(prisma: PrismaService, orderId: string, type: MessageType, limit: number, cursor?: string): Promise<ChatMessageWithSender[]> {
  return prisma.chatMessage.findMany({
    where: { orderId, type }, orderBy: { createdAt: 'desc' }, take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}), ...CHAT_MESSAGE_WITH_SENDER_ARGS,
  });
}

export async function messageBelongsToThread(prisma: PrismaService, messageId: string, threadId: string, model: ChatThreadType): Promise<boolean> {
  if (model === ChatThreadType.ORDER) return (await prisma.chatMessage.findFirst({ where: { id: messageId, orderId: threadId }, select: { id: true } })) !== null;
  return (await prisma.directMessage.findFirst({ where: { id: messageId, conversationId: threadId }, select: { id: true } })) !== null;
}

export async function findReplyToSummary(prisma: PrismaService, id: string): Promise<ReplyToSummary | null> {
  const directMessage = await prisma.directMessage.findUnique({ where: { id }, ...DIRECT_REPLY_ARGS });
  if (directMessage) return directMessage;
  const chatMessage = await prisma.chatMessage.findUnique({ where: { id }, ...CHAT_REPLY_ARGS });
  if (chatMessage) return { ...chatMessage, conversationId: chatMessage.orderId };
  return null;
}
