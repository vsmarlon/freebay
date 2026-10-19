import { Test } from '@nestjs/testing';
import { AccountLifecycleDatabaseRepository } from './account-lifecycle-database.repository';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

type DelegateName =
  | 'user' | 'post' | 'story' | 'directMessage' | 'chatMessage' | 'pushDevice' | 'notification'
  | 'passwordRecoveryCode' | 'savedPost' | 'favorite' | 'cartItem' | 'conversationPreference'
  | 'follow' | 'block' | 'closeFriend' | 'restriction' | 'like' | 'share' | 'commentLike' | 'webMagicLink'
  | 'messageReaction' | 'starredMessage' | 'phoneVerificationCode' | 'storyHighlight' | 'storyView'
  | 'comment' | 'product' | 'productImage' | 'like' | 'share' | 'commentLike' | 'report' | 'bugReport' | 'moderationAction';

describe('AccountLifecycleDatabaseRepository personal purge', () => {
  const cutoff = new Date('2026-09-09T00:00:00.000Z');
  const purgedAt = new Date('2026-10-09T00:00:00.000Z');

  function setup(user: Record<string, unknown>) {
    const calls: Array<{ delegate: string; method: string; args: unknown[] }> = [];
    const delegates = new Map<string, Record<string, jest.Mock>>();
    const names: DelegateName[] = [
      'user', 'post', 'story', 'directMessage', 'chatMessage', 'pushDevice', 'notification',
      'passwordRecoveryCode', 'savedPost', 'favorite', 'cartItem', 'conversationPreference',
      'follow', 'block', 'closeFriend', 'restriction', 'like', 'share', 'commentLike', 'webMagicLink',
      'messageReaction', 'starredMessage', 'phoneVerificationCode', 'storyHighlight', 'storyView',
      'comment', 'product', 'productImage', 'like', 'share', 'commentLike', 'report', 'bugReport', 'moderationAction',
    ];
    for (const delegate of names) {
      delegates.set(delegate, {
        findUnique: jest.fn().mockImplementation(async (...args: unknown[]) => {
          calls.push({ delegate, method: 'findUnique', args });
          return delegate === 'user' ? user : null;
        }),
        findMany: jest.fn().mockImplementation(async (...args: unknown[]) => {
          calls.push({ delegate, method: 'findMany', args });
          return [];
        }),
        count: jest.fn().mockImplementation(async (...args: unknown[]) => {
          calls.push({ delegate, method: 'count', args });
          return 0;
        }),
        updateMany: jest.fn().mockImplementation(async (...args: unknown[]) => {
          calls.push({ delegate, method: 'updateMany', args });
          const update = args[0];
          if (delegate === 'user' && update && typeof update === 'object' && 'data' in update && update.data && typeof update.data === 'object') {
            Object.assign(user, update.data);
          }
          return { count: 1 };
        }),
        deleteMany: jest.fn().mockImplementation(async (...args: unknown[]) => {
          calls.push({ delegate, method: 'deleteMany', args });
          return { count: 0 };
        }),
      });
    }
    const transaction = new Proxy({}, {
      get: (_target, property: string) => property === '$queryRaw' ? jest.fn().mockResolvedValue([]) : delegates.get(property),
    });
    const prisma = {
      user: delegates.get('user'),
      $transaction: jest.fn(async (...args: unknown[]) => {
        const callback = args[0];
        if (typeof callback !== 'function') throw new Error('Expected transaction callback');
        return Reflect.apply(callback, undefined, [transaction]);
      }),
    };
    return { calls, delegates, prisma };
  }

  async function repositoryFor(prisma: ReturnType<typeof setup>['prisma']) {
    const module = await Test.createTestingModule({
      providers: [
        AccountLifecycleDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: AuthSessionStateDatabaseRepository, useValue: {} },
      ],
    }).compile();
    return module.get(AccountLifecycleDatabaseRepository);
  }

  it('rejects a request canceled or rescheduled beyond the cutoff before any destructive write', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-10T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
    });
    const repository = await repositoryFor(prisma);

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isRight() && result.value).toBe('canceled');
    expect(delegates.get('user')?.updateMany).not.toHaveBeenCalled();
    expect(calls.filter(({ method }) => method === 'deleteMany' || method === 'updateMany')).toEqual([]);
  });

  it('queues authored media before redaction, tombstones personal content, and keeps linked financial records outside purge writes', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-08T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
      email: 'person@example.test',
      avatarUrl: '/uploads/avatar.png',
      bannerUrl: '/uploads/banner.png',
    });
    delegates.get('post')?.findMany.mockResolvedValue([{ imageUrl: '/uploads/post.png' }]);
    delegates.get('story')?.findMany.mockResolvedValue([{ imageUrl: '/uploads/story.png' }]);
    delegates.get('directMessage')?.findMany.mockResolvedValue([{ attachmentUrl: '/uploads/direct.png' }]);
    delegates.get('chatMessage')?.findMany.mockResolvedValue([{ attachmentUrl: '/uploads/order-chat.png' }]);
    delegates.get('comment')?.findMany.mockResolvedValueOnce([]).mockResolvedValueOnce([{ id: 'comment-1' }]);
    delegates.get('comment')?.findUnique.mockResolvedValue({ postId: 'post-1', isHidden: false, deletedAt: null, replies: [] });
    const repository = await repositoryFor(prisma);

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isRight() && result.value).toBe('pending-media');
    const userWrite = calls.find(({ delegate, method }) => delegate === 'user' && method === 'updateMany');
    expect(userWrite?.args[0]).toMatchObject({ data: {
      personalPurgePendingMedia: [
        '/uploads/avatar.png', '/uploads/banner.png', '/uploads/post.png', '/uploads/story.png',
        '/uploads/direct.png', '/uploads/order-chat.png',
      ],
      personalPurgeCompletedAt: null,
      webConsentIp: null,
      webConsentUserAgent: null,
      lastSeenAt: null,
    }, where: { deletionRequestedAt: { equals: new Date('2026-09-08T00:00:00.000Z'), lte: cutoff } } });
    expect(calls).toContainEqual(expect.objectContaining({ delegate: 'comment', method: 'updateMany' }));
    expect(calls).toContainEqual(expect.objectContaining({ delegate: 'directMessage', method: 'updateMany' }));
    expect(calls).toContainEqual(expect.objectContaining({ delegate: 'chatMessage', method: 'updateMany' }));
    expect(calls.some(({ delegate }) => ['order', 'transaction', 'wallet', 'walletEntry', 'dispute', 'review', 'reviewImage'].includes(delegate))).toBe(false);
  });

  it('scrubs and queues only an orderless listing with no inquiry reference', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-08T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
      email: 'person@example.test',
      avatarUrl: null,
      bannerUrl: null,
    });
    delegates.get('product')?.findMany
      .mockResolvedValueOnce([{ id: 'listing-1', images: [{ url: '/uploads/listing.png' }], directConversations: [] }])
      .mockResolvedValueOnce([]);
    delegates.get('product')?.findUnique.mockResolvedValue({
      sellerId: 'user-1', deletedAt: null, orders: [], images: [{ url: '/uploads/listing.png' }],
      directConversations: [], favorites: [], cartItems: [], post: null,
    });
    const repository = await repositoryFor(prisma);

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isRight() && result.value).toBe('pending-media');
    expect(calls.find(({ delegate, method }) => delegate === 'user' && method === 'updateMany')?.args[0]).toMatchObject({
      data: { personalPurgePendingMedia: ['/uploads/listing.png'], personalPurgeCompletedAt: null },
    });
    expect(calls.find(({ delegate, method }) => delegate === 'product' && method === 'updateMany')?.args[0]).toMatchObject({
      where: { id: 'listing-1', orders: { none: {} }, directConversations: { none: {} } },
      data: { title: 'Anúncio removido', description: '', status: 'PAUSED' },
    });
    expect(calls.find(({ delegate, method }) => delegate === 'productImage' && method === 'updateMany')?.args[0]).toMatchObject({
      where: { productId: 'listing-1' }, data: { url: '', blurHash: null },
    });
  });

  it('leaves an already-purged pending account retryable without repeating personal deletes', async () => {
    const { calls, prisma } = setup({
      deletionRequestedAt: null,
      deletedAt: purgedAt,
      personalPurgePendingMedia: ['/uploads/unverified.png'],
      personalPurgeCompletedAt: null,
    });
    const repository = await repositoryFor(prisma);

    await repository.findPurgeCandidates(cutoff);
    expect(calls.find(({ delegate, method }) => delegate === 'user' && method === 'findMany')?.args[0]).toMatchObject({
      where: { OR: expect.arrayContaining([expect.objectContaining({
        deletedAt: { not: null }, personalPurgeCompletedAt: null,
      })]) },
    });

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isRight() && result.value).toBe('pending-media');
    expect(calls.filter(({ method }) => method === 'deleteMany' || method === 'updateMany')).toEqual([]);
  });

  it('fails the transaction instead of reporting completion when a personal scrub fails after media collection', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-08T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
      email: 'person@example.test',
      avatarUrl: '/uploads/avatar.png',
      bannerUrl: null,
    });
    delegates.get('post')?.updateMany.mockRejectedValue(new Error('synthetic database failure'));
    const repository = await repositoryFor(prisma);

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isLeft()).toBe(true);
    expect(calls.find(({ delegate, method }) => delegate === 'user' && method === 'updateMany')?.args[0]).toMatchObject({
      data: { personalPurgePendingMedia: ['/uploads/avatar.png'], personalPurgeCompletedAt: null },
    });
  });

  it('keeps completion unset while report or moderation retention remains unresolved', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-08T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
      email: 'person@example.test',
      avatarUrl: null,
      bannerUrl: null,
    });
    delegates.get('bugReport')?.count.mockResolvedValue(1);
    const repository = await repositoryFor(prisma);

    const result = await repository.purge('user-1', cutoff, purgedAt);

    expect(result.isRight() && result.value).toBe('pending-review');
    expect(calls.find(({ delegate, method }) => delegate === 'user' && method === 'updateMany')?.args[0]).toMatchObject({
      data: { personalPurgePendingMedia: [], personalPurgeCompletedAt: null },
    });
  });

  it('decrements only aggregates represented by actually removed owner reactions and is idempotent on retry', async () => {
    const { calls, delegates, prisma } = setup({
      deletionRequestedAt: new Date('2026-09-08T00:00:00.000Z'),
      deletedAt: null,
      personalPurgePendingMedia: [],
      personalPurgeCompletedAt: null,
      email: 'person@example.test',
      avatarUrl: null,
      bannerUrl: null,
    });
    delegates.get('like')?.findMany.mockResolvedValue([{ postId: 'post-1' }]);
    delegates.get('share')?.findMany.mockResolvedValue([{ postId: 'post-1' }]);
    delegates.get('commentLike')?.findMany.mockResolvedValue([{ commentId: 'comment-1' }]);
    delegates.get('like')?.deleteMany.mockResolvedValue({ count: 1 });
    delegates.get('share')?.deleteMany.mockResolvedValue({ count: 1 });
    delegates.get('commentLike')?.deleteMany.mockResolvedValue({ count: 1 });
    const repository = await repositoryFor(prisma);

    const first = await repository.purge('user-1', cutoff, purgedAt);
    const second = await repository.purge('user-1', cutoff, purgedAt);

    expect(first.isRight() && first.value).toBe('completed');
    expect(second.isRight() && second.value).toBe('completed');
    const postCounterWrites = calls.filter(({ delegate, method }) => delegate === 'post' && method === 'updateMany').map(({ args }) => args[0]);
    const commentCounterWrites = calls.filter(({ delegate, method }) => delegate === 'comment' && method === 'updateMany').map(({ args }) => args[0]);
    expect(postCounterWrites).toEqual(expect.arrayContaining([
      expect.objectContaining({ where: { id: 'post-1', likesCount: { gt: 0 } }, data: { likesCount: { decrement: 1 } } }),
      expect.objectContaining({ where: { id: 'post-1', sharesCount: { gt: 0 } }, data: { sharesCount: { decrement: 1 } } }),
    ]));
    expect(commentCounterWrites).toContainEqual(expect.objectContaining({
      where: { id: 'comment-1', deletedAt: null, likesCount: { gt: 0 } }, data: { likesCount: { decrement: 1 } },
    }));
  });
});
