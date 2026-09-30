import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetFeedUseCase } from '../../usecases/get-feed.usecase';
import { PrismaPostRepository } from './post-database.repository';
import { prisma } from '../../../../../test/setup-integration';
import { FeedType } from '../../types/social.types';

describe('Explore feed pagination (real PostgreSQL)', () => {
  let database: PrismaService;
  let feed: GetFeedUseCase;

  beforeAll(async () => {
    database = new PrismaService(new ConfigService());
    await database.$connect();
    feed = new GetFeedUseCase(new PrismaPostRepository(database));
  });

  afterAll(async () => {
    await database.$disconnect();
  });

  it('reaches every post beyond the first 300 without duplicates', async () => {
    const user = await prisma.user.create({
      data: { email: `feed-pages-${Date.now()}@example.com`, displayName: 'Feed' },
    });
    const base = new Date('2026-09-28T12:00:00.000Z').getTime();
    await prisma.post.createMany({
      data: Array.from({ length: 315 }, (_, index) => ({
        userId: user.id,
        type: 'REGULAR',
        content: `Post ${index}`,
        createdAt: new Date(base - index * 60_000),
      })),
    });

    const seen = new Set<string>();
    let cursor: string | undefined;
    for (let page = 0; page < 17; page++) {
      const result = await feed.execute({ limit: 20, cursor });
      if (result.isLeft()) throw result.value;
      expect(result.value.posts.length).toBeGreaterThan(0);
      expect(result.value.posts.length).toBeLessThanOrEqual(20);
      for (const post of result.value.posts) {
        expect(seen.has(post.id)).toBe(false);
        seen.add(post.id);
      }
      if (!result.value.hasMore) {
        expect(result.value.nextCursor).toBeNull();
        break;
      }
      expect(result.value.nextCursor).toBeTruthy();
      cursor = result.value.nextCursor ?? undefined;
    }
    expect(seen.size).toBe(315);
  });

  it('keeps the remaining window stable when engagement changes between pages', async () => {
    const user = await prisma.user.create({
      data: { email: `feed-stable-${Date.now()}@example.com`, displayName: 'Feed' },
    });
    const createdAt = new Date('2026-09-28T12:00:00.000Z');
    const posts = await Promise.all([4, 3, 2, 1].map((likesCount, index) =>
      prisma.post.create({ data: {
        userId: user.id, type: 'REGULAR', content: `post-${index}`,
        likesCount, createdAt,
      } }),
    ));

    const first = await feed.execute({ limit: 2 });
    if (first.isLeft() || !first.value.nextCursor) throw new Error('first page failed');
    await prisma.post.update({ where: { id: posts[2].id }, data: { likesCount: 100 } });
    const second = await feed.execute({ limit: 2, cursor: first.value.nextCursor });
    if (second.isLeft()) throw second.value;

    const ids = [...first.value.posts, ...second.value.posts].map((post) => post.id);
    expect(ids).toHaveLength(4);
    expect(new Set(ids)).toEqual(new Set(posts.map((post) => post.id)));
  });

  it('filters the Following feed without loading the entire follow graph into memory', async () => {
    const [viewer, followed, stranger] = await Promise.all(['viewer', 'followed', 'stranger'].map((name) =>
      prisma.user.create({ data: { email: `feed-${name}-${Date.now()}@example.com`, displayName: name } }),
    ));
    await prisma.follow.create({ data: { followerId: viewer.id, followingId: followed.id } });
    await prisma.post.createMany({ data: [followed, stranger].map((user) => ({
      userId: user.id, type: 'REGULAR', content: 'Hello',
    })) });
    const listFollows = jest.spyOn(database.follow, 'findMany');

    try {
      const result = await feed.execute({ userId: viewer.id, type: FeedType.FOLLOWING });
      if (result.isLeft()) throw result.value;
      expect(result.value.posts.map((post) => post.userId)).toEqual([followed.id]);
      expect(listFollows).not.toHaveBeenCalled();
    } finally {
      listFollows.mockRestore();
    }
  });
});
