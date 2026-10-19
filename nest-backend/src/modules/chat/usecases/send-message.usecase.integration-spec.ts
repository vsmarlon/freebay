import { Test } from '@nestjs/testing';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory } from '../../../../test/factories';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { BlockDatabaseRepository } from '@/modules/users/data/repositories/block-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { OG_HTML_FETCHER, OgScraperService } from '../services/og-scraper.service';
import { UrlSafetyService } from '../services/url-safety.service';
import { SendMessageUseCase } from './send-message.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { FcmService } from '@/modules/notifications/fcm.service';
import { NotificationsGateway } from '@/modules/notifications/notifications.gateway';
import { ConversationPreferenceDatabaseRepository } from '../data/repositories/conversation-preference-database.repository';

describe('SendMessageUseCase location integration', () => {
  it('persists canonical metadata and reuses a duplicate client id', async () => {
    const users = new UserFactory(prisma);
    const sender = await users.create();
    const receiver = await users.create();
    const sendFcm = jest.fn();
    const sendNotification = jest.fn();
    const conversation = await prisma.directConversation.create({
      data: {
        user1Id: sender.id < receiver.id ? sender.id : receiver.id,
        user2Id: sender.id < receiver.id ? receiver.id : sender.id,
        status: 'ACTIVE',
      },
    });
    const module = await Test.createTestingModule({
      providers: [
        SendMessageUseCase,
        ConversationDatabaseRepository,
        BlockDatabaseRepository,
        UrlSafetyService,
        OgScraperService,
        { provide: OG_HTML_FETCHER, useValue: async () => '' },
        ChatThreadAccessService,
        ConversationPreferenceDatabaseRepository,
        NotificationService,
        { provide: FcmService, useValue: { sendNotification: sendFcm } },
        { provide: NotificationsGateway, useValue: { sendNotification } },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    const usecase = module.get(SendMessageUseCase);
    const metadata = {
      latitude: -23.5505,
      longitude: -46.6333,
      accuracyMeters: 3,
      capturedAt: new Date().toISOString(),
      address: 'São Paulo',
    };

    const first = await usecase.execute({
      senderId: sender.id,
      conversationId: conversation.id,
      clientMessageId: 'location-integration-1',
      type: 'LOCATION',
      metadata,
    });
    const second = await usecase.execute({
      senderId: sender.id,
      conversationId: conversation.id,
      clientMessageId: 'location-integration-1',
      type: 'LOCATION',
      metadata,
    });

    expect(first.isRight()).toBe(true);
    expect(second.isRight()).toBe(true);
    if (first.isLeft() || second.isLeft()) throw new Error('Message send failed');
    expect(second.value.message.id).toBe(first.value.message.id);
    expect(await prisma.notification.count({ where: { id: first.value.message.id, userId: receiver.id } })).toBe(1);
    expect(sendNotification).toHaveBeenCalledTimes(1);
    expect(sendFcm).toHaveBeenCalledTimes(1);
    const persisted = await prisma.directMessage.findMany({
      where: { conversationId: conversation.id, clientMessageId: 'location-integration-1' },
    });
    expect(persisted).toHaveLength(1);
    expect(persisted[0].metadata).toEqual(metadata);
    expect(persisted[0].clientMessageId).toBe('location-integration-1');
  });
});
