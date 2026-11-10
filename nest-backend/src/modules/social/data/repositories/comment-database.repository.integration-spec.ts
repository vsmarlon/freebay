import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { CommentDatabaseRepository } from './comment-database.repository';
import { randomUUID } from 'node:crypto';

describe('CommentDatabaseRepository comment counters', () => {
  let database: PrismaService;
  let repository: CommentDatabaseRepository;

  beforeAll(async () => {
    database = new PrismaService(new ConfigService());
    await database.$connect();
    repository = new CommentDatabaseRepository(database);
  });

  afterAll(async () => {
    await database.$disconnect();
  });

  it('increments once for a root comment and once for its reply', async () => {
    const user = await prisma.user.create({ data: { email: `fb08-${Date.now()}@example.com`, displayName: 'FB-08' } });
    const post = await prisma.post.create({ data: { userId: user.id, type: 'REGULAR', content: 'post' } });
    const root = await repository.createWithCount(
      { content: 'root', user: { connect: { id: user.id } }, post: { connect: { id: post.id } } },
      post.id,
      user.id,
      user.id,
    );
    expect(root.isRight()).toBe(true);

    if (root.isLeft()) return;
    const reply = await repository.createWithCount(
      {
        content: 'reply',
        user: { connect: { id: user.id } },
        post: { connect: { id: post.id } },
        parent: { connect: { id: root.value.id } },
      },
      post.id,
      user.id,
      user.id,
    );
    expect(reply.isRight()).toBe(true);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.commentsCount).toBe(2);
  });

  it('rolls back the comment when the counter update fails', async () => {
    const user = await prisma.user.create({ data: { email: `fb08-fail-${Date.now()}@example.com`, displayName: 'FB-08' } });
    const post = await prisma.post.create({ data: { userId: user.id, type: 'REGULAR', content: 'post' } });
    const result = await repository.createWithCount(
      { content: 'not persisted', user: { connect: { id: user.id } }, post: { connect: { id: post.id } } },
      '00000000-0000-0000-0000-000000000000',
      user.id,
      user.id,
    );

    expect(result.isLeft()).toBe(true);
    expect(await prisma.comment.count({ where: { postId: post.id } })).toBe(0);
  });

  it('decrements once when deleting a root with replies', async () => {
    const user = await prisma.user.create({ data: { email: `fb08-delete-${Date.now()}@example.com`, displayName: 'FB-08' } });
    const post = await prisma.post.create({ data: { userId: user.id, type: 'REGULAR', content: 'post' } });
    const root = await repository.createWithCount(
      { content: 'root', user: { connect: { id: user.id } }, post: { connect: { id: post.id } } },
      post.id,
      user.id,
      user.id,
    );
    if (root.isLeft()) return;
    await repository.createWithCount(
      {
        content: 'reply',
        user: { connect: { id: user.id } },
        post: { connect: { id: post.id } },
        parent: { connect: { id: root.value.id } },
      },
      post.id,
      user.id,
      user.id,
    );

    expect((await repository.softDeleteWithCount(root.value.id)).value).toBe(true);
    expect((await repository.softDeleteWithCount(root.value.id)).value).toBe(false);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.commentsCount).toBe(1);
    expect(await prisma.comment.count({ where: { postId: post.id, deletedAt: null } })).toBe(1);
  });

  it('replays the canonical comment once, rejects a changed digest, and rechecks access on replay', async () => {
    const owner = await prisma.user.create({ data: { email: `fb08-owner-${Date.now()}@example.com`, displayName: 'Owner' } });
    const commenter = await prisma.user.create({ data: { email: `fb08-author-${Date.now()}@example.com`, displayName: 'Author' } });
    const post = await prisma.post.create({ data: { userId: owner.id, type: 'REGULAR', content: 'post' } });
    const requestId = randomUUID();
    const input = { content: 'reply', user: { connect: { id: commenter.id } }, post: { connect: { id: post.id } } };
    const options = { postId: post.id, userId: commenter.id, requestId, digest: 'payload-a', mentionIds: [] };

    const first = await repository.createIdempotent(input, options);
    const replay = await repository.createIdempotent(input, options);
    const changed = await repository.createIdempotent({ ...input, content: 'changed' }, { ...options, digest: 'payload-b' });
    expect(first.isRight() && replay.isRight() && first.value.comment.id === replay.value.comment.id).toBe(true);
    expect(replay.isRight() && replay.value.replayed).toBe(true);
    expect(changed.isLeft()).toBe(true);
    expect(await prisma.comment.count({ where: { postId: post.id } })).toBe(1);
    expect((await prisma.post.findUnique({ where: { id: post.id } }))?.commentsCount).toBe(1);

    await prisma.block.create({ data: { blockerId: owner.id, blockedId: commenter.id } });
    expect((await repository.createIdempotent(input, options)).isLeft()).toBe(true);
  });
});
