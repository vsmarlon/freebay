import { Test } from '@nestjs/testing';
import { ChatThreadType } from '@prisma/client';
import { prisma } from '../../../../test/setup-integration';
import { OrderFactory, ProductFactory, UserFactory } from '../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ConversationPreferenceDatabaseRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ViewOnceUseCase } from './view-once.usecase';

const OPENING_KEY_A = '550e8400-e29b-41d4-a716-446655440000';
const OPENING_KEY_B = '550e8400-e29b-41d4-a716-446655440001';

describe.each([ChatThreadType.DIRECT, ChatThreadType.ORDER])('PostgreSQL chat privacy: %s', (threadType) => {
  it('allows one concurrent view-once opening, same-key retry, closure, history denial, generic-read exclusion, and persisted mute', async () => {
    const users = new UserFactory(prisma);
    const sender = await users.create();
    const recipient = await users.create();
    const outsider = await users.create();
    let conversationId: string;
    let messageId: string;

    if (threadType === ChatThreadType.DIRECT) {
      const conversation = await prisma.directConversation.create({
        data: {
          user1Id: sender.id < recipient.id ? sender.id : recipient.id,
          user2Id: sender.id < recipient.id ? recipient.id : sender.id,
          status: 'ACTIVE',
        },
      });
      conversationId = conversation.id;
      const message = await prisma.directMessage.create({
        data: {
          conversationId,
          senderId: sender.id,
          type: 'IMAGE',
          attachmentUrl: '/media/chat/view-once.jpg',
          viewOnce: true,
        },
      });
      messageId = message.id;
    } else {
      const product = await new ProductFactory(prisma).create(sender.id);
      const order = await new OrderFactory(prisma).create(recipient.id, sender.id, product.id);
      conversationId = order.id;
      const message = await prisma.chatMessage.create({
        data: {
          orderId: conversationId,
          senderId: sender.id,
          type: 'IMAGE',
          attachmentUrl: '/media/chat/view-once.jpg',
          viewOnce: true,
        },
      });
      messageId = message.id;
    }

    const module = await Test.createTestingModule({
      providers: [
        ViewOnceUseCase,
        ConversationDatabaseRepository,
        ConversationPreferenceDatabaseRepository,
        ChatThreadAccessService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    const viewOnce = module.get(ViewOnceUseCase);
    const repository = module.get(ConversationDatabaseRepository);
    const preferenceRepository = module.get(ConversationPreferenceDatabaseRepository);

    const contenders = await Promise.all([
      viewOnce.open(conversationId, messageId, recipient.id, OPENING_KEY_A),
      viewOnce.open(conversationId, messageId, recipient.id, OPENING_KEY_B),
    ]);
    expect(contenders.filter((result) => result.isRight())).toHaveLength(1);
    expect(contenders.filter((result) => result.isLeft())).toHaveLength(1);

    const winnerIndex = contenders.findIndex((result) => result.isRight());
    const winnerKey = winnerIndex === 0 ? OPENING_KEY_A : OPENING_KEY_B;
    const winner = contenders[winnerIndex];
    if (winner.isLeft()) throw new Error('Concurrent view-once claim has no winner');

    const retry = await viewOnce.open(conversationId, messageId, recipient.id, winnerKey);
    expect(retry).toEqual(winner);
    const wrongKey = await viewOnce.open(conversationId, messageId, recipient.id, winnerIndex === 0 ? OPENING_KEY_B : OPENING_KEY_A);
    expect(wrongKey.isLeft()).toBe(true);
    expect((await viewOnce.open(conversationId, messageId, sender.id, winnerKey)).isLeft()).toBe(true);
    expect((await viewOnce.open(conversationId, messageId, outsider.id, winnerKey)).isLeft()).toBe(true);

    expect((await viewOnce.close(conversationId, messageId, recipient.id, winnerKey)).isRight()).toBe(true);
    expect((await viewOnce.close(conversationId, messageId, recipient.id, winnerKey)).isRight()).toBe(true);
    expect((await viewOnce.open(conversationId, messageId, recipient.id, winnerKey)).isLeft()).toBe(true);

    const historical = threadType === ChatThreadType.ORDER
      ? await prisma.chatMessage.create({ data: { orderId: conversationId, senderId: sender.id, viewOnce: true, readAt: new Date(), attachmentUrl: '/media/chat/history.jpg' } })
      : await prisma.directMessage.create({ data: { conversationId, senderId: sender.id, viewOnce: true, readAt: new Date(), attachmentUrl: '/media/chat/history.jpg' } });
    expect((await viewOnce.open(conversationId, historical.id, recipient.id, OPENING_KEY_A)).isLeft()).toBe(true);

    const genericReadTarget = threadType === ChatThreadType.ORDER
      ? await prisma.chatMessage.create({ data: { orderId: conversationId, senderId: sender.id, viewOnce: true, attachmentUrl: '/media/chat/generic-read.jpg' } })
      : await prisma.directMessage.create({ data: { conversationId, senderId: sender.id, viewOnce: true, attachmentUrl: '/media/chat/generic-read.jpg' } });
    const genericRead = threadType === ChatThreadType.ORDER
      ? await repository.markChatMessagesRead(conversationId, recipient.id)
      : await repository.markMessagesRead(conversationId, recipient.id);
    expect(genericRead.isRight()).toBe(true);
    const genericReadRecord = threadType === ChatThreadType.ORDER
      ? await prisma.chatMessage.findUnique({ where: { id: genericReadTarget.id } })
      : await prisma.directMessage.findUnique({ where: { id: genericReadTarget.id } });
    expect(genericReadRecord?.readAt).toBeNull();

    const preferenceInput = {
      userId: recipient.id,
      ...(threadType === ChatThreadType.ORDER ? { orderId: conversationId } : { directConversationId: conversationId }),
      muted: true,
    };
    expect((await preferenceRepository.upsert(preferenceInput)).isRight()).toBe(true);
    const preference = await preferenceRepository.findByUserAndThread(recipient.id, conversationId, threadType);
    expect(preference.isRight() && preference.value?.muted).toBe(true);
    const outsiderPreference = await preferenceRepository.findByUserAndThread(outsider.id, conversationId, threadType);
    expect(outsiderPreference.isRight() && outsiderPreference.value).toBeNull();
    const unrelatedThread = await preferenceRepository.findByUserAndThread(recipient.id, 'unrelated-thread-id', threadType);
    expect(unrelatedThread.isRight() && unrelatedThread.value).toBeNull();
  });
});
