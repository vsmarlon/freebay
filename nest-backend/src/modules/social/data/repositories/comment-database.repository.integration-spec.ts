import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { PrismaCommentRepository } from './comment-database.repository';

describe('PrismaCommentRepository comment counters', () => {
  let database: PrismaService;
  let repository: PrismaCommentRepository;

  beforeAll(async () => {
    database = new PrismaService(new ConfigService());
    await database.$connect();
    repository = new PrismaCommentRepository(database);
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
});
