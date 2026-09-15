import { Test } from '@nestjs/testing';
import { Prisma, ConversationStatus, DirectMessage } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConversationDatabaseRepository } from './conversation-database.repository';
import { ProductConversationSummaryRecord, productConversationSummaryValidator } from '../../mappers/conversation.mapper';

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
});
