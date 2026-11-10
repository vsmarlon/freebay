import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { LikeDatabaseRepository } from './like-database.repository';
import { ShareDatabaseRepository } from './share-database.repository';
import { CommentDatabaseRepository } from './comment-database.repository';
import { randomUUID } from 'node:crypto';

/**
 * Concurrency + counter-convergence proofs for the social mutation contract.
 * These cannot be asserted against mocks: they depend on the unique indexes and
 * transactional reads of a real PostgreSQL instance (see jest.config.integration.js).
 */
describe('Social interactions (integration)', () => {
  let database: PrismaService;
  let likeRepository: LikeDatabaseRepository;
  let shareRepository: ShareDatabaseRepository;
  let commentRepository: CommentDatabaseRepository;

  const seedUser = (suffix: string) =>
    prisma.user.create({ data: { email: `soc-${suffix}-${Date.now()}-${randomUUID().slice(0, 6)}@example.com`, displayName: `SOC-${suffix}` } });
  const seedPost = (userId: string) =>
    prisma.post.create({ data: { userId, type: 'REGULAR', content: 'social integration post' } });

  beforeAll(async () => {
    database = new PrismaService(new ConfigService());
    await database.$connect();
    likeRepository = new LikeDatabaseRepository(database);
    shareRepository = new ShareDatabaseRepository(database);
    commentRepository = new CommentDatabaseRepository(database);
  });

  afterAll(async () => {
    await database.$disconnect();
  });

  it('records a burst of concurrent distinct likes exactly once each', async () => {
    const author = await seedUser('author');
    const post = await seedPost(author.id);
    const users = await Promise.all(Array.from({ length: 12 }, () => seedUser('liker')));

    const results = await Promise.all(users.map((user) => likeRepository.setPostLike(user.id, post.id, true)));

    expect(results.filter((r) => r.isRight()).length).toBe(12);
    expect(await prisma.like.count({ where: { postId: post.id } })).toBe(12);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.likesCount).toBe(12);
  });

  it('keeps one stale double-click from the same user at exactly one like', async () => {
    const author = await seedUser('author2');
    const post = await seedPost(author.id);
    const liker = await seedUser('liker2');

    const [first, second] = await Promise.all([
      likeRepository.setPostLike(liker.id, post.id, true),
      likeRepository.setPostLike(liker.id, post.id, true),
    ]);

    expect(first.isRight()).toBe(true);
    expect(second.isRight()).toBe(true);
    expect(await prisma.like.count({ where: { postId: post.id } })).toBe(1);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.likesCount).toBe(1);
    if (first.isRight() && second.isRight()) {
      expect(first.value).toEqual({ active: true, count: 1 });
      expect(second.value).toEqual({ active: true, count: 1 });
    }
  });

  it('converges the denormalized counter with like rows through like → unlike cycles', async () => {
    const author = await seedUser('author3');
    const post = await seedPost(author.id);
    const users = await Promise.all([seedUser('a'), seedUser('b'), seedUser('c')]);

    await Promise.all(users.map((user) => likeRepository.setPostLike(user.id, post.id, true)));
    await likeRepository.setPostLike(users[2].id, post.id, false);
    await likeRepository.setPostLike(users[2].id, post.id, true);

    const rows = await prisma.like.count({ where: { postId: post.id } });
    const column = (await prisma.post.findUnique({ where: { id: post.id } }))?.likesCount;
    expect(column).toBe(rows);
    expect(rows).toBe(3);
  });

  it('does not duplicate a repost on a concurrent double-tap', async () => {
    const author = await seedUser('author4');
    const post = await seedPost(author.id);
    const reposter = await seedUser('rep');

    const [first, second] = await Promise.all([
      shareRepository.setPostShare(reposter.id, post.id, true),
      shareRepository.setPostShare(reposter.id, post.id, true),
    ]);

    expect(first.isRight()).toBe(true);
    expect(second.isRight()).toBe(true);
    expect(await prisma.share.count({ where: { postId: post.id } })).toBe(1);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.sharesCount).toBe(1);
  });

  it('tracks comments against the visible-comment filter, not raw rows', async () => {
    const author = await seedUser('author6');
    const commenter = await seedUser('commenter6');
    const post = await seedPost(author.id);
    const requestId = `vis-${randomUUID()}`;

    const visible = await commentRepository.createIdempotent(
      { content: 'visible one', post: { connect: { id: post.id } }, user: { connect: { id: commenter.id } } },
      { postId: post.id, userId: commenter.id, requestId, digest: 'd1', mentionIds: [] },
    );
    expect(visible.isRight()).toBe(true);
    const visibleId = visible.isRight() ? visible.value.comment.id : '';
    if (visible.isRight()) expect(visible.value.commentsCount).toBe(1);

    // A restricted commenter's comment is stored but never counted.
    await prisma.restriction.create({ data: { ownerId: author.id, restrictedId: commenter.id } });
    try {
      const hidden = await commentRepository.createIdempotent(
        { content: 'hidden one', post: { connect: { id: post.id } }, user: { connect: { id: commenter.id } } },
        { postId: post.id, userId: commenter.id, requestId: `hid-${randomUUID()}`, digest: 'd2', mentionIds: [] },
      );
      expect(hidden.isRight()).toBe(true);
      if (hidden.isRight()) expect(hidden.value.commentsCount).toBe(1);
    } finally {
      await prisma.restriction.deleteMany({ where: { ownerId: author.id, restrictedId: commenter.id } });
    }

    // Retrying the identical payload replays the original comment without re-counting.
    const replay = await commentRepository.createIdempotent(
      { content: 'visible one', post: { connect: { id: post.id } }, user: { connect: { id: commenter.id } } },
      { postId: post.id, userId: commenter.id, requestId, digest: 'd1', mentionIds: [] },
    );
    expect(replay.isRight()).toBe(true);
    if (replay.isRight()) {
      expect(replay.value.comment.id).toBe(visibleId);
      expect(replay.value.commentsCount).toBe(1);
    }

    // Deleting the visible comment counts it down; the hidden one is absent from both sides.
    const removed = await commentRepository.softDeleteWithCount(visibleId);
    expect(removed.isRight()).toBe(true);
    expect(removed.isRight() && removed.value).toBe(true);
    const column = (await prisma.post.findUnique({ where: { id: post.id } }))?.commentsCount;
    const visibleRows = await prisma.comment.count({
      where: { postId: post.id, deletedAt: null, isHidden: false, authorHiddenAt: null },
    });
    expect(column).toBe(visibleRows);
    expect(visibleRows).toBe(0);
  });
});
