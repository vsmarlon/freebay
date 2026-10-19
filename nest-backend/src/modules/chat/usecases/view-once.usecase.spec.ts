import { createHash } from 'crypto';
import { Test } from '@nestjs/testing';
import { ChatThreadType } from '@prisma/client';
import { right } from '@/shared/core/either';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ViewOnceUseCase } from './view-once.usecase';

describe('ViewOnceUseCase', () => {
  it.each([
    { thread: { directConversationId: 'direct-1', otherUserId: 'sender-1' }, type: ChatThreadType.DIRECT },
    { thread: { orderId: 'order-1', otherUserId: 'sender-1' }, type: ChatThreadType.ORDER },
  ])('uses a hashed key for $type claim and returns only the media contract', async ({ thread, type }) => {
    const openingKey = '550e8400-e29b-41d4-a716-446655440000';
    const readAt = new Date('2026-10-09T12:00:00.000Z');
    const resolveThread = jest.fn().mockResolvedValue(right(thread));
    const claimViewOnce = jest.fn().mockResolvedValue(right({ readAt, attachmentUrl: '/media/chat/media.jpg' }));
    const module = await Test.createTestingModule({
      providers: [
        ViewOnceUseCase,
        { provide: ChatThreadAccessService, useValue: { resolveThread } },
        { provide: ConversationDatabaseRepository, useValue: { claimViewOnce } },
      ],
    }).compile();

    const result = await module.get(ViewOnceUseCase).open('thread-url-id', 'message-1', 'recipient-1', openingKey);

    expect(claimViewOnce).toHaveBeenCalledWith(
      'message-1', type === ChatThreadType.ORDER ? 'order-1' : 'direct-1', 'recipient-1', type,
      createHash('sha256').update(openingKey).digest('hex'),
    );
    expect(result).toEqual(right({ messageId: 'message-1', readAt, mediaUrl: '/media/chat/media.jpg' }));
    if (result.isRight()) {
      expect(JSON.stringify(result.value)).not.toContain('viewOnceOpeningHash');
      expect(JSON.stringify(result.value)).not.toContain(openingKey);
    }
  });
});
