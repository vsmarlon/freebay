import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaPostRepository } from './post-database.repository';
import { decodeFeedCursor } from '../../types/social.types';

const post = (id: string, userId: string, createdAt: Date, likesCount: number) => ({
  id,
  userId,
  type: 'REGULAR',
  content: id,
  imageUrl: null,
  productId: null,
  deletedAt: null,
  createdAt,
  updatedAt: createdAt,
  user: { id: userId, displayName: userId, username: userId, avatarUrl: null, isVerified: false },
  likes: [],
  savedBy: [],
  shares: [],
  _count: { likes: likesCount, comments: 0, shares: 0 },
  product: null,
});

describe('PrismaPostRepository feed affinity', () => {
  it('keeps duplicate follow rows from changing ranking, pagination, or ties', async () => {
    const createdAt = new Date('2026-09-20T00:00:00.000Z');
    const candidates = [
      post('followed', 'author-followed', createdAt, 1),
      post('other', 'author-other', createdAt, 1),
      post('tie-a', 'author-other', createdAt, 0),
      post('tie-b', 'author-other', createdAt, 0),
    ];
    const run = async (followingIdRows: string[]) => {
      const module = await Test.createTestingModule({
        providers: [
          PrismaPostRepository,
          {
            provide: PrismaService,
            useValue: {
              follow: { findMany: jest.fn().mockResolvedValue(followingIdRows.map((followingId) => ({ followingId }))) },
              post: { findMany: jest.fn().mockResolvedValue(candidates) },
            },
          },
        ],
      }).compile();
      const result = await module.get(PrismaPostRepository).findFeed({ userId: 'viewer', limit: 3 });
      if (result.isLeft()) throw new Error('feed query failed');
      return { ids: result.value.posts.map(({ id }) => id), nextCursor: result.value.nextCursor };
    };

    await expect(run(['author-followed'])).resolves.toEqual(
      await run(['author-followed', 'author-followed']),
    );
    const page = await run(['author-followed']);
    expect(page.ids).toEqual(['followed', 'other', 'tie-a']);
    expect(page.nextCursor).toBeTruthy();
  });

  it('surfaces another author before a third consecutive post across pages', async () => {
    const createdAt = new Date();
    const candidates = [
      post('a1', 'author-a', createdAt, 5),
      post('a2', 'author-a', createdAt, 4),
      post('a3', 'author-a', createdAt, 3),
      post('b1', 'author-b', createdAt, 0),
    ];
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        {
          provide: PrismaService,
          useValue: {
            post: { findMany: jest.fn().mockResolvedValue(candidates) },
          },
        },
      ],
    }).compile();
    const repository = module.get(PrismaPostRepository);

    const first = await repository.findFeed({ limit: 2 });
    if (first.isLeft() || !first.value.nextCursor) throw new Error('feed query failed');
    const cursor = decodeFeedCursor(first.value.nextCursor);
    if (!cursor) throw new Error('feed cursor invalid');
    const second = await repository.findFeed({ limit: 2, cursor });
    if (second.isLeft()) throw new Error('feed query failed');

    expect(first.value.posts.map(({ id }) => id)).toEqual(['a1', 'a2']);
    expect(second.value.posts.map(({ id }) => id)).toEqual(['b1', 'a3']);
    expect(cursor.scope).toBe('explore-feed');
    expect(second.value.hasMore).toBe(false);
  });
});
