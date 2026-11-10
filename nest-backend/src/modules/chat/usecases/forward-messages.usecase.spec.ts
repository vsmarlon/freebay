import { Test, TestingModule } from '@nestjs/testing';
import { ForwardMessagesUseCase } from './forward-messages.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { BlockDatabaseRepository } from '@/modules/users/data/repositories/block-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BadRequestError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { deleteUpload, isOwnedUpload, saveUpload } from '@/shared/utils/file.utils';
import { readdirSync } from 'fs';
import { join } from 'path';

const mockPrisma = {
  directMessage: {
    findMany: jest.fn(),
  },
  chatMessage: {
    findMany: jest.fn(),
  },
};

const mockRepo = {
  createDirectMessage: jest.fn(),
  updateDirectConversation: jest.fn(),
  createChatMessage: jest.fn(),
};

const mockBlockRepository = {
  isBlocked: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

describe('ForwardMessagesUseCase', () => {
  let sut: ForwardMessagesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ForwardMessagesUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: BlockDatabaseRepository, useValue: mockBlockRepository },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(ForwardMessagesUseCase);
    jest.clearAllMocks();
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
  });

  it('returns error when no message IDs provided', async () => {
    const result = await sut.execute({
      userId: 'user-1',
      messageIds: [],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns error when no target conversation IDs provided', async () => {
    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: [],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('returns error when source messages not found', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if recipient has blocked user', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([
      { id: 'msg-1', content: 'Hey', type: 'TEXT', attachmentUrl: null, metadata: null, sender: { displayName: 'John' } },
    ]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'conv-1', otherUserId: 'user-blocked' }));
    mockBlockRepository.isBlocked.mockResolvedValueOnce(right(true));

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-1'],
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(ForbiddenError);
  });

  it('successfully forwards messages to target direct conversations', async () => {
    mockPrisma.directMessage.findMany.mockResolvedValue([
      { id: 'msg-1', content: 'Hello World', type: 'TEXT', attachmentUrl: null, metadata: null, sender: { displayName: 'John' } },
    ]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'conv-target', otherUserId: 'user-2' }));
    mockBlockRepository.isBlocked.mockResolvedValue(right(false));
    mockRepo.createDirectMessage.mockResolvedValue(right({
      id: 'new-msg-1',
      conversationId: 'conv-target',
      senderId: 'user-1',
      content: 'Hello World',
      type: 'TEXT',
      attachmentUrl: null,
      createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({
      userId: 'user-1',
      messageIds: ['msg-1'],
      targetConversationIds: ['conv-target'],
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.forwardedCount).toBe(1);
      expect(result.value.messages[0].content).toBe('Hello World');
      expect(result.value.messages[0].metadata).toEqual(expect.objectContaining({
        isForwarded: true,
        forwardedFrom: 'John',
      }));
    }
  });

  it.each(['wrong-owner', 'unmarked'])('refuses %s media before writing any target message', async (proof) => {
    const originalUrl = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('source') }, 'chat', proof === 'unmarked' ? undefined : 'original-owner');
    mockPrisma.directMessage.findMany.mockResolvedValue([{
      id: 'media-1', content: null, type: 'IMAGE', attachmentUrl: originalUrl, metadata: null,
      senderId: proof === 'wrong-owner' ? 'someone-else' : 'original-owner', sender: { displayName: 'Original' },
      viewOnce: false, readAt: null, conversationId: 'source-thread',
    }]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'target', otherUserId: 'user-2' }));

    const result = await sut.execute({ userId: 'forwarder', messageIds: ['media-1'], targetConversationIds: ['target'] });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
    deleteUpload(originalUrl);
  });

  it('copies owned media with new ownership for repeated forwards', async () => {
    const originalUrl = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('source') }, 'chat', 'original-owner');
    mockPrisma.directMessage.findMany.mockResolvedValue([{
      id: 'media-1', content: null, type: 'IMAGE', attachmentUrl: originalUrl, metadata: null,
      senderId: 'original-owner', sender: { displayName: 'Original' }, viewOnce: false, readAt: null,
      conversationId: 'source-thread',
    }]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'target', otherUserId: 'user-2' }));
    mockRepo.createDirectMessage.mockImplementation(async (data: { attachmentUrl: string | null }) => right({
      id: 'forwarded-1', conversationId: 'target', senderId: 'forwarder', content: null, type: 'IMAGE',
      attachmentUrl: data.attachmentUrl, createdAt: new Date(),
    }));
    mockRepo.updateDirectConversation.mockResolvedValue(right({}));

    const result = await sut.execute({ userId: 'forwarder', messageIds: ['media-1'], targetConversationIds: ['target'] });

    expect(result.isRight()).toBe(true);
    const copiedUrl = mockRepo.createDirectMessage.mock.calls[0][0].attachmentUrl;
    expect(copiedUrl).not.toBe(originalUrl);
    expect(isOwnedUpload(copiedUrl, 'forwarder', 'chat')).toBe(true);
    expect(isOwnedUpload(copiedUrl, 'original-owner', 'chat')).toBe(false);

    mockPrisma.directMessage.findMany.mockResolvedValue([{
      id: 'forwarded-1', content: null, type: 'IMAGE', attachmentUrl: copiedUrl, metadata: null,
      senderId: 'forwarder', sender: { displayName: 'Forwarder' }, viewOnce: false, readAt: null,
      conversationId: 'target',
    }]);
    const secondResult = await sut.execute({ userId: 'recipient-1', messageIds: ['forwarded-1'], targetConversationIds: ['target-2'] });
    const secondCopyUrl = mockRepo.createDirectMessage.mock.calls[1][0].attachmentUrl;
    expect(secondResult.isRight()).toBe(true);
    expect(secondCopyUrl).not.toBe(copiedUrl);
    expect(isOwnedUpload(secondCopyUrl, 'recipient-1', 'chat')).toBe(true);
    deleteUpload(originalUrl);
    deleteUpload(copiedUrl);
    deleteUpload(secondCopyUrl);
  });

  it.each(['left', 'throw'])('removes the copied media if target persistence returns %s', async (failureMode) => {
    const originalUrl = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('source') }, 'chat', 'original-owner');
    mockPrisma.directMessage.findMany.mockResolvedValue([{
      id: 'media-1', content: null, type: 'IMAGE', attachmentUrl: originalUrl, metadata: null,
      senderId: 'original-owner', sender: { displayName: 'Original' }, viewOnce: false, readAt: null,
      conversationId: 'source-thread',
    }]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'target', otherUserId: 'user-2' }));
    if (failureMode === 'throw') {
      mockRepo.createDirectMessage.mockRejectedValue(new Error('database unavailable'));
    } else {
      mockRepo.createDirectMessage.mockResolvedValue({ isLeft: () => true, value: new BadRequestError('failed') });
    }

    const result = await sut.execute({ userId: 'forwarder', messageIds: ['media-1'], targetConversationIds: ['target'] });

    expect(result.isLeft()).toBe(true);
    const copiedUrl = mockRepo.createDirectMessage.mock.calls[0][0].attachmentUrl;
    expect(isOwnedUpload(originalUrl, 'original-owner', 'chat')).toBe(true);
    expect(isOwnedUpload(copiedUrl, 'forwarder', 'chat')).toBe(false);
    deleteUpload(originalUrl);
  });

  it.each(['unauthorized', 'blocked'])('preflights all targets and writes nothing when a later target is %s', async (failureMode) => {
    const sourceUrl = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('source') }, 'chat', 'source-owner');
    const directory = join(process.cwd(), 'private-uploads', 'chat');
    const filesBefore = readdirSync(directory).sort();
    mockPrisma.directMessage.findMany.mockResolvedValue([{
      id: 'media-1', content: null, type: 'IMAGE', attachmentUrl: sourceUrl, metadata: null,
      senderId: 'source-owner', sender: { displayName: 'Original' }, viewOnce: false, readAt: null,
      conversationId: 'source-thread',
    }]);
    mockPrisma.chatMessage.findMany.mockResolvedValue([]);
    mockThreadAccess.resolveThread
      .mockResolvedValueOnce(right({ directConversationId: 'source-thread', otherUserId: 'source-other' }))
      .mockResolvedValueOnce(right({ directConversationId: 'target-one', otherUserId: 'target-one-user' }))
      .mockResolvedValueOnce(failureMode === 'unauthorized'
        ? { isLeft: () => true, value: new ForbiddenError('no access') }
        : right({ directConversationId: 'target-two', otherUserId: 'target-two-user' }));
    if (failureMode === 'blocked') {
      mockBlockRepository.isBlocked
        .mockResolvedValueOnce(right(false)).mockResolvedValueOnce(right(false))
        .mockResolvedValueOnce(right(true));
    }

    const result = await sut.execute({
      userId: 'forwarder', messageIds: ['media-1'], targetConversationIds: ['target-one', 'target-two'],
    });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createDirectMessage).not.toHaveBeenCalled();
    expect(readdirSync(directory).sort()).toEqual(filesBefore);
    deleteUpload(sourceUrl);
  });
});
