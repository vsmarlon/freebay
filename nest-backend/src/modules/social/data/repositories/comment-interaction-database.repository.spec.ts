import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { NotFoundError } from "@/shared/core/errors";
import { CommentInteractionDatabaseRepository } from "./comment-interaction-database.repository";

const repositoryWith = (prisma: object) =>
  new CommentInteractionDatabaseRepository(prisma as PrismaService);

const txWith = (overrides: {
  visible?: { id: string; postId: string } | null;
  upsertResult?: { id: string };
}) => ({
  comment: { findFirst: jest.fn().mockResolvedValue(overrides.visible ?? null) },
  commentShare: { upsert: jest.fn().mockResolvedValue(overrides.upsertResult ?? { id: 'share-1' }) },
});

describe('CommentInteractionDatabaseRepository.setReposted', () => {
  it('reposts a visible comment with an idempotent upsert', async () => {
    const tx = txWith({ visible: { id: 'comment-1', postId: 'post-1' }, upsertResult: { id: 'share-1' } });
    const repository = repositoryWith({ $transaction: (work: (client: object) => Promise<unknown>) => work(tx) });

    const result = await repository.setReposted('user-1', 'comment-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.commentShare.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { userId_commentId: { userId: 'user-1', commentId: 'comment-1' } },
      create: { userId: 'user-1', commentId: 'comment-1', postId: 'post-1' },
      update: {},
    }));
    if (result.isRight()) expect(result.value).toEqual({ active: true, id: 'share-1' });
  });

  it('returns NotFound for an invisible comment without writing a repost', async () => {
    const tx = txWith({ visible: null });
    const repository = repositoryWith({ $transaction: (work: (client: object) => Promise<unknown>) => work(tx) });

    const result = await repository.setReposted('user-1', 'comment-1', true);

    expect(result.isLeft()).toBe(true);
    expect(result.isLeft() && result.value).toBeInstanceOf(NotFoundError);
    expect(tx.commentShare.upsert).not.toHaveBeenCalled();
  });

  it('reposting twice keeps a single repost row (empty update branch is idempotent)', async () => {
    const tx = txWith({ visible: { id: 'comment-1', postId: 'post-1' } });
    const repository = repositoryWith({ $transaction: (work: (client: object) => Promise<unknown>) => work(tx) });

    const first = await repository.setReposted('user-1', 'comment-1', true);
    const second = await repository.setReposted('user-1', 'comment-1', true);

    expect(first.isRight()).toBe(true);
    expect(second.isRight()).toBe(true);
    expect(tx.commentShare.upsert).toHaveBeenCalledTimes(2);
    expect(tx.commentShare.upsert).toHaveBeenLastCalledWith(expect.objectContaining({ update: {} }));
    if (second.isRight()) expect(second.value).toEqual({ active: true, id: 'share-1' });
  });

  it('unreposting without a repost row is a no-op that reports inactive', async () => {
    const deleteMany = jest.fn().mockResolvedValue({ count: 0 });
    const repository = repositoryWith({ commentShare: { deleteMany } });

    const result = await repository.setReposted('user-1', 'comment-1', false);

    expect(result.isRight()).toBe(true);
    expect(deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1', commentId: 'comment-1' } });
    if (result.isRight()) expect(result.value).toEqual({ active: false });
  });
});
