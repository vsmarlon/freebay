import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaPostRepository } from './post-database.repository';

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
      const result = await module.get(PrismaPostRepository).findFeed({ userId: 'viewer', limit: 3, offset: 0 });
      if (result.isLeft()) throw new Error('feed query failed');
      return { ids: result.value.posts.map(({ id }) => id), nextOffset: result.value.nextOffset };
    };

    await expect(run(['author-followed'])).resolves.toEqual(
      await run(['author-followed', 'author-followed']),
    );
    await expect(run(['author-followed'])).resolves.toEqual({
      ids: ['followed', 'other', 'tie-a'],
      nextOffset: 3,
    });
  });
});
