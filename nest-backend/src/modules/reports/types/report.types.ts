import { Prisma } from '@prisma/client';

export type DirectMessageWithConversation = Prisma.DirectMessageGetPayload<{ include: { conversation: true } }>;

export type ChatMessageWithOrder = Prisma.ChatMessageGetPayload<{ include: { order: true } }>;
