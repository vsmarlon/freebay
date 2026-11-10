import { Test } from '@nestjs/testing';
import { Logger } from '@nestjs/common';
import { Prisma, ConversationStatus, DirectMessage, MessageReaction, ChatThreadType } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConversationDatabaseRepository } from './conversation-database.repository';
import { DirectMessageWithSender, ProductConversationSummaryRecord, productConversationSummaryValidator } from '../../types/conversation-payloads';

type ConversationWithProduct = {
  id: string;
  status: ConversationStatus;
  product: ProductConversationSummaryRecord | null;
};

describe('ConversationDatabaseRepository', () => {
  it('rereads the canonical conversation after a Prisma P2002', async () => {
    const create = jest.fn<Promise<ConversationWithProduct>, [Prisma.DirectConversationCreateArgs]>();
    const findFirst = jest.fn<Promise<ConversationWithProduct | null>, [Prisma.DirectConversationFindFirstArgs]>();
    const canonical = { id: 'canonical', status: ConversationStatus.ACTIVE, product: null };
    create.mockRejectedValue(new Prisma.PrismaClientKnownRequestError('unique', {
      code: 'P2002',
      clientVersion: 'test',
    }));
    findFirst.mockResolvedValue(canonical);

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { directConversation: { create, findFirst } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.createDirectConversation({
      user1: { connect: { id: 'user-1' } },
      user2: { connect: { id: 'user-2' } },
      scopeKey: 'PRODUCT:product-1',
    });

    expect(result.isRight()).toBe(true);
    expect(findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { user1Id: 'user-1', user2Id: 'user-2', scopeKey: 'PRODUCT:product-1' },
      include: { product: { select: productConversationSummaryValidator.select } },
    }));
    if (result.isRight()) expect(result.value.conversationId).toBe('canonical');
  });

  it('keeps non-unique database failures as failures', async () => {
    const create = jest.fn<Promise<ConversationWithProduct>, [Prisma.DirectConversationCreateArgs]>();
    const findFirst = jest.fn<Promise<ConversationWithProduct | null>, [Prisma.DirectConversationFindFirstArgs]>();
    create.mockRejectedValue(new Error('database unavailable'));

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { directConversation: { create, findFirst } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.createDirectConversation({
      user1: { connect: { id: 'user-1' } },
      user2: { connect: { id: 'user-2' } },
      scopeKey: 'DIRECT',
    });

    expect(result.isLeft()).toBe(true);
    expect(findFirst).not.toHaveBeenCalled();
  });

  it('logs database failures with the repository context', async () => {
    const findUnique = jest.fn<Promise<null>, [Prisma.UserFindUniqueArgs]>();
    findUnique.mockRejectedValue(new Error('database unavailable'));
    const logger = jest.spyOn(Logger, 'error').mockImplementation();

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { user: { findUnique } } },
      ],
    }).compile();

    const result = await module.get(ConversationDatabaseRepository).findUserById('user-1');

    expect(result.isLeft()).toBe(true);
    expect(logger).toHaveBeenCalledWith('Erro ao buscar usuário', expect.any(String), 'ConversationDatabaseRepository');
    logger.mockRestore();
  });

  it('only reconciles a duplicate direct message for the same sender', async () => {
    const create = jest.fn<Promise<DirectMessage>, [Prisma.DirectMessageCreateArgs]>();
    const findFirst = jest.fn<Promise<DirectMessage | null>, [Prisma.DirectMessageFindFirstArgs]>();
    create.mockRejectedValue(new Prisma.PrismaClientKnownRequestError('unique', {
      code: 'P2002',
      clientVersion: 'test',
    }));
    findFirst.mockResolvedValue(null);

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        {
          provide: PrismaService,
          useValue: { directMessage: { create, findFirst } },
        },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.createDirectMessage({
      conversation: { connect: { id: 'conversation-1' } },
      sender: { connect: { id: 'sender-1' } },
      clientMessageId: 'client-1',
    });

    expect(result.isLeft()).toBe(true);
    expect(findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: {
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        clientMessageId: 'client-1',
      },
    }));
  });

  it('creates a reaction when the user has not reacted', async () => {
    const findFirst = jest.fn<Promise<MessageReaction | null>, [Prisma.MessageReactionFindFirstArgs]>();
    const create = jest.fn<Promise<MessageReaction>, [Prisma.MessageReactionCreateArgs]>();
    findFirst.mockResolvedValue(null);
    create.mockResolvedValue({ id: 'reaction-1', emoji: 'â¤ï¸', userId: 'user-1', directMessageId: 'message-1', chatMessageId: null, createdAt: new Date() });

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { messageReaction: { findFirst, create } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.upsertReaction({ userId: 'user-1', messageId: 'message-1', emoji: 'â¤ï¸', model: ChatThreadType.DIRECT });

    expect(result.isRight()).toBe(true);
    expect(create).toHaveBeenCalled();
  });

  it('updates an existing reaction', async () => {
    const findFirst = jest.fn<Promise<MessageReaction | null>, [Prisma.MessageReactionFindFirstArgs]>();
    const update = jest.fn<Promise<MessageReaction>, [Prisma.MessageReactionUpdateArgs]>();
    const existing = { id: 'reaction-1', emoji: 'Ã°Å¸â€˜Â', userId: 'user-1', directMessageId: 'message-1', chatMessageId: null, createdAt: new Date() };
    findFirst.mockResolvedValue(existing);
    update.mockResolvedValue({ ...existing, emoji: 'â¤ï¸' });

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { messageReaction: { findFirst, update } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.upsertReaction({ userId: 'user-1', messageId: 'message-1', emoji: 'â¤ï¸', model: ChatThreadType.DIRECT });

    expect(result.isRight()).toBe(true);
    expect(update).toHaveBeenCalledWith({ where: { id: 'reaction-1' }, data: { emoji: 'â¤ï¸' } });
  });

  it('does not create a reaction when the existence read fails', async () => {
    const findFirst = jest.fn<Promise<MessageReaction | null>, [Prisma.MessageReactionFindFirstArgs]>();
    const create = jest.fn<Promise<MessageReaction>, [Prisma.MessageReactionCreateArgs]>();
    findFirst.mockRejectedValue(new Error('database unavailable'));

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { messageReaction: { findFirst, create } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.upsertReaction({ userId: 'user-1', messageId: 'message-1', emoji: 'â¤ï¸', model: ChatThreadType.DIRECT });

    expect(result.isLeft()).toBe(true);
    expect(create).not.toHaveBeenCalled();
  });

  it('returns starred messages in star order', async () => {
    const starredFindMany = jest.fn<Promise<{ directMessageId: string | null; chatMessageId: string | null }[]>, [Prisma.StarredMessageFindManyArgs]>();
    const directFindMany = jest.fn<Promise<DirectMessageWithSender[]>, [Prisma.DirectMessageFindManyArgs]>();
    const message = (id: string): DirectMessageWithSender => ({
      id,
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      clientMessageId: null,
      content: id,
      type: 'TEXT',
      attachmentUrl: null,
      metadata: null,
      deliveredAt: null,
      readAt: null,
      replyToId: null,
      viewOnce: false,
      viewOnceOpeningHash: null,
      viewOnceClosedAt: null,
      deletedAt: null,
      createdAt: new Date(),
      sender: { id: 'sender-1', displayName: 'Sender', avatarUrl: null },
      replyTo: null,
    });
    starredFindMany.mockResolvedValue([{ directMessageId: 'message-2', chatMessageId: null }, { directMessageId: 'message-1', chatMessageId: null }]);
    directFindMany.mockResolvedValue([message('message-1'), message('message-2')]);

    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { starredMessage: { findMany: starredFindMany }, directMessage: { findMany: directFindMany } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = await repository.findStarredMessages('user-1', 'conversation-1', ChatThreadType.DIRECT);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.map(({ id }) => id)).toEqual(['message-2', 'message-1']);
  });

  it.each([
    { model: ChatThreadType.DIRECT, count: 2 },
    { model: ChatThreadType.ORDER, count: 1 },
    { model: ChatThreadType.DIRECT, count: 0 },
  ])('returns the persisted read count for $model', async ({ model, count }) => {
    const updateMany = jest.fn().mockResolvedValue({ count });
    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { directMessage: { updateMany }, chatMessage: { updateMany } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const result = model === ChatThreadType.ORDER
      ? await repository.markChatMessagesRead('thread-1', 'reader-1')
      : await repository.markMessagesRead('thread-1', 'reader-1');

    expect(result).toEqual(expect.objectContaining({ value: count }));
    expect(updateMany).toHaveBeenCalledWith(expect.objectContaining({ where: expect.objectContaining({ viewOnce: false }) }));
  });

  it('keeps a failed mark-read update as a repository failure', async () => {
    const updateMany = jest.fn().mockRejectedValue(new Error('database unavailable'));
    const module = await Test.createTestingModule({
      providers: [ConversationDatabaseRepository, { provide: PrismaService, useValue: { directMessage: { updateMany } } }],
    }).compile();

    const result = await module.get(ConversationDatabaseRepository).markMessagesRead('thread-1', 'reader-1');

    expect(result.isLeft()).toBe(true);
  });

  it('claims an unread view-once message with compare-and-set and retries the same key without resetting readAt', async () => {
    const readAt = new Date('2026-10-09T12:00:00.000Z');
    const findFirst = jest.fn()
      .mockResolvedValueOnce({ readAt: null, attachmentUrl: '/media/chat/media.jpg', viewOnceOpeningHash: null, viewOnceClosedAt: null })
      .mockResolvedValueOnce({ readAt, attachmentUrl: '/media/chat/media.jpg' })
      .mockResolvedValueOnce({ readAt, attachmentUrl: '/media/chat/media.jpg', viewOnceOpeningHash: 'a'.repeat(64), viewOnceClosedAt: null });
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const module = await Test.createTestingModule({
      providers: [
        ConversationDatabaseRepository,
        { provide: PrismaService, useValue: { directMessage: { findFirst, updateMany } } },
      ],
    }).compile();
    const repository = module.get(ConversationDatabaseRepository);

    const first = await repository.claimViewOnce('message-1', 'direct-1', 'reader-1', ChatThreadType.DIRECT, 'a'.repeat(64));
    const retry = await repository.claimViewOnce('message-1', 'direct-1', 'reader-1', ChatThreadType.DIRECT, 'a'.repeat(64));

    expect(first).toEqual(expect.objectContaining({ value: { readAt, attachmentUrl: '/media/chat/media.jpg' } }));
    expect(retry).toEqual(expect.objectContaining({ value: { readAt, attachmentUrl: '/media/chat/media.jpg' } }));
    expect(updateMany).toHaveBeenCalledTimes(1);
    expect(updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ readAt: null, viewOnceOpeningHash: null, viewOnceClosedAt: null, senderId: { not: 'reader-1' } }),
      data: expect.objectContaining({ readAt: expect.any(Date), deliveredAt: expect.any(Date), viewOnceOpeningHash: 'a'.repeat(64) }),
    }));
  });
});
