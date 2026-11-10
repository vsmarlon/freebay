import { Test } from '@nestjs/testing';
import { ChatTheme } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConversationPreferenceDatabaseRepository } from './conversation-preference-database.repository';

describe('ConversationPreferenceDatabaseRepository', () => {
  it('persists mute without resetting the existing theme or unrelated preference fields', async () => {
    const upsert = jest.fn().mockResolvedValue({
      id: 'preference-1',
      userId: 'user-1',
      orderId: null,
      directConversationId: 'conversation-1',
      isArchived: false,
      isDeleted: false,
      muted: true,
      deletedAt: null,
      theme: ChatTheme.COBALT,
      backgroundUrl: '/media/background/background.jpg',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const module = await Test.createTestingModule({
      providers: [
        ConversationPreferenceDatabaseRepository,
        { provide: PrismaService, useValue: { conversationPreference: { upsert } } },
      ],
    }).compile();

    const result = await module.get(ConversationPreferenceDatabaseRepository).upsert({
      userId: 'user-1',
      directConversationId: 'conversation-1',
      muted: true,
    });

    expect(result.isRight()).toBe(true);
    expect(upsert).toHaveBeenCalledWith({
      where: { userId_directConversationId: { userId: 'user-1', directConversationId: 'conversation-1' } },
      create: {
        userId: 'user-1', orderId: null, directConversationId: 'conversation-1',
        isArchived: false, isDeleted: false, muted: true, theme: ChatTheme.DEFAULT, backgroundUrl: null,
      },
      update: { isArchived: undefined, isDeleted: undefined, muted: true, theme: undefined, backgroundUrl: undefined },
    });
  });
});
