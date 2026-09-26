import { MessageReaction, ChatThreadType, StarredMessage } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ChatMessageWithSender, DirectMessageWithSender, messageWithSenderInclude } from '../../../mappers/conversation.mapper';

export function findReactionByUserAndMessage(prisma: PrismaService, userId: string, messageId: string, model: ChatThreadType): Promise<MessageReaction | null> {
  const where = model === 'DIRECT' ? { userId, directMessageId: messageId } : { userId, chatMessageId: messageId };
  return prisma.messageReaction.findFirst({ where });
}

export async function upsertReaction(prisma: PrismaService, data: { userId: string; messageId: string; emoji: string; model: ChatThreadType }): Promise<void> {
  let existing: MessageReaction | null = null;
  existing = await findReactionByUserAndMessage(prisma, data.userId, data.messageId, data.model);
  if (existing) {
    await prisma.messageReaction.update({ where: { id: existing.id }, data: { emoji: data.emoji } });
  } else {
    const msgField = data.model === 'DIRECT' ? 'directMessageId' : 'chatMessageId';
    await prisma.messageReaction.create({ data: { userId: data.userId, [msgField]: data.messageId, emoji: data.emoji } });
  }
}

export function deleteReaction(prisma: PrismaService, reactionId: string): Promise<MessageReaction> {
  return prisma.messageReaction.delete({ where: { id: reactionId } });
}

export function getReactionsForMessage(prisma: PrismaService, messageId: string, model: ChatThreadType): Promise<{ emoji: string; userId: string }[]> {
  const where = model === 'DIRECT' ? { directMessageId: messageId } : { chatMessageId: messageId };
  return prisma.messageReaction.findMany({ where, select: { emoji: true, userId: true } });
}

export function findStarByUserAndMessage(prisma: PrismaService, userId: string, messageId: string, model: ChatThreadType): Promise<StarredMessage | null> {
  const where = model === 'DIRECT' ? { userId, directMessageId: messageId } : { userId, chatMessageId: messageId };
  return prisma.starredMessage.findFirst({ where });
}

export function createStar(prisma: PrismaService, data: { userId: string; messageId: string; model: ChatThreadType }): Promise<StarredMessage> {
  const msgField = data.model === 'DIRECT' ? 'directMessageId' : 'chatMessageId';
  return prisma.starredMessage.create({ data: { userId: data.userId, [msgField]: data.messageId } });
}

export function deleteStar(prisma: PrismaService, starId: string): Promise<StarredMessage> {
  return prisma.starredMessage.delete({ where: { id: starId } });
}

export async function findStarredMessages(prisma: PrismaService, userId: string, threadId: string, model: ChatThreadType): Promise<(DirectMessageWithSender | ChatMessageWithSender)[]> {
  const stars = await prisma.starredMessage.findMany({
    where: { userId, ...(model === 'DIRECT' ? { directMessage: { conversationId: threadId } } : { chatMessage: { orderId: threadId } }) },
    select: { directMessageId: true, chatMessageId: true }, orderBy: { createdAt: 'desc' },
  });
  const ids = stars.map((star) => star.directMessageId ?? star.chatMessageId).filter((id): id is string => id != null);
  if (ids.length === 0) return [];
  if (model === 'DIRECT') {
    const messages = await prisma.directMessage.findMany({ where: { id: { in: ids } }, include: messageWithSenderInclude });
    const byId = new Map(messages.map((message) => [message.id, message]));
    return ids.flatMap((id) => {
      const message = byId.get(id);
      return message ? [message] : [];
    });
  }
  const messages = await prisma.chatMessage.findMany({ where: { id: { in: ids } }, include: messageWithSenderInclude });
  const byId = new Map(messages.map((message) => [message.id, message]));
  return ids.flatMap((id) => {
    const message = byId.get(id);
    return message ? [message] : [];
  });
}
