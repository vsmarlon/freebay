import { Test } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { ForbiddenError } from '@/shared/core/errors';
import { deleteUpload, saveUpload } from '@/shared/utils/file.utils';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { ConversationPreferenceDatabaseRepository } from '../data/repositories/conversation-preference-database.repository';
import { SetConversationBackgroundUseCase } from './set-conversation-background.usecase';

describe('SetConversationBackgroundUseCase upload ownership', () => {
  const threadAccess = { resolveThread: jest.fn() };
  const preferences = { upsert: jest.fn() };
  let sut: SetConversationBackgroundUseCase;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        SetConversationBackgroundUseCase,
        { provide: ChatThreadAccessService, useValue: threadAccess },
        { provide: ConversationPreferenceDatabaseRepository, useValue: preferences },
      ],
    }).compile();
    sut = module.get(SetConversationBackgroundUseCase);
    jest.clearAllMocks();
    threadAccess.resolveThread.mockResolvedValue(right({ directConversationId: 'conversation-1', otherUserId: 'user-2' }));
    preferences.upsert.mockResolvedValue(right({ backgroundUrl: '/preference/background.png' }));
  });

  it('persists only an owned background after thread access is authorized', async () => {
    const url = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('image') }, 'background', 'user-1');
    try {
      const result = await sut.execute('user-1', 'conversation-1', url);

      expect(result.isRight()).toBe(true);
      expect(preferences.upsert).toHaveBeenCalledWith({
        userId: 'user-1', orderId: undefined, directConversationId: 'conversation-1', backgroundUrl: url,
      });
    } finally {
      deleteUpload(url);
    }
  });

  it.each(['wrong-owner', 'missing-file', 'missing-marker', 'wrong-context', 'path-traversal'])(
    'rejects %s backgrounds before checking or changing conversation preferences', async (kind) => {
      let url: string;
      if (kind === 'wrong-owner') {
        url = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('image') }, 'background', 'user-2');
      } else if (kind === 'missing-marker') {
        url = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('image') }, 'background');
      } else if (kind === 'wrong-context') {
        url = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('image') }, 'chat', 'user-1');
      } else if (kind === 'missing-file') {
        url = '/media/background/00000000-0000-0000-0000-000000000001.png';
      } else {
        url = '/media/background/../00000000-0000-0000-0000-000000000001.png';
      }

      try {
        const result = await sut.execute('user-1', 'conversation-1', url);

        expect(result.isLeft()).toBe(true);
        expect(threadAccess.resolveThread).not.toHaveBeenCalled();
        expect(preferences.upsert).not.toHaveBeenCalled();
      } finally {
        deleteUpload(url);
      }
    },
  );

  it('preserves thread authorization failures for a valid owned background', async () => {
    const url = saveUpload({ mimetype: 'image/png', buffer: Buffer.from('image') }, 'background', 'user-1');
    threadAccess.resolveThread.mockResolvedValue(left(new ForbiddenError('not a participant')));
    try {
      const result = await sut.execute('user-1', 'conversation-1', url);

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) expect(result.value).toBeInstanceOf(ForbiddenError);
      expect(preferences.upsert).not.toHaveBeenCalled();
    } finally {
      deleteUpload(url);
    }
  });
});
