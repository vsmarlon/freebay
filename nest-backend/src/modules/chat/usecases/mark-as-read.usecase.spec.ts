import { Test } from '@nestjs/testing';
import { ChatThreadType } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { MarkAsReadUseCase } from './mark-as-read.usecase';

describe('MarkAsReadUseCase', () => {
  it.each([
    { thread: { directConversationId: 'direct-1', otherUserId: 'other-1' }, method: 'markMessagesRead' },
    { thread: { orderId: 'order-1', otherUserId: 'other-1' }, method: 'markChatMessagesRead' },
  ])('returns the changed-row count for $method', async ({ thread, method }) => {
    const resolveThread = jest.fn().mockResolvedValue(right(thread));
    const markMessagesRead = jest.fn().mockResolvedValue(right(3));
    const markChatMessagesRead = jest.fn().mockResolvedValue(right(3));
    const module = await Test.createTestingModule({
      providers: [
        MarkAsReadUseCase,
        { provide: ChatThreadAccessService, useValue: { resolveThread } },
        { provide: ConversationDatabaseRepository, useValue: { markMessagesRead, markChatMessagesRead } },
      ],
    }).compile();

    const result = await module.get(MarkAsReadUseCase).execute('thread-url-id', 'reader-1');

    expect(result).toEqual(right(3));
    expect(method === 'markMessagesRead' ? markMessagesRead : markChatMessagesRead).toHaveBeenCalledWith(
      method === 'markMessagesRead' ? 'direct-1' : 'order-1', 'reader-1',
    );
  });

  it('does not pass an explicit view-once ID into the generic read update', async () => {
    const resolveThread = jest.fn().mockResolvedValue(right({ directConversationId: 'direct-1', otherUserId: 'other-1' }));
    const messageBelongsToThread = jest.fn().mockResolvedValue(right(true));
    const markMessagesRead = jest.fn().mockResolvedValue(right(0));
    const module = await Test.createTestingModule({
      providers: [
        MarkAsReadUseCase,
        { provide: ChatThreadAccessService, useValue: { resolveThread } },
        { provide: ConversationDatabaseRepository, useValue: { messageBelongsToThread, markMessagesRead } },
      ],
    }).compile();

    const result = await module.get(MarkAsReadUseCase).execute('direct-1', 'reader-1', 'view-once-1');

    expect(result).toEqual(right(0));
    expect(messageBelongsToThread).toHaveBeenCalledWith('view-once-1', 'direct-1', ChatThreadType.DIRECT);
    expect(markMessagesRead).toHaveBeenCalledWith('direct-1', 'reader-1', 'view-once-1');
  });

  it('propagates authorization and repository errors', async () => {
    const failure = new AppError('READ_FAILED', 'failed');
    const resolveThread = jest.fn().mockResolvedValue(left(failure));
    const markMessagesRead = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        MarkAsReadUseCase,
        { provide: ChatThreadAccessService, useValue: { resolveThread } },
        { provide: ConversationDatabaseRepository, useValue: { markMessagesRead } },
      ],
    }).compile();

    const result = await module.get(MarkAsReadUseCase).execute('thread-1', 'reader-1');

    expect(result).toEqual(left(failure));
    expect(markMessagesRead).not.toHaveBeenCalled();
  });
});
