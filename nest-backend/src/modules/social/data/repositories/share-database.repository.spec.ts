import { Test } from '@nestjs/testing';
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { ShareDatabaseRepository } from "./share-database.repository";

/**
 * In-memory stand-in for the share table + Post.sharesCount column keyed to the
 * repost contract: one Share row per (userId, postId), guarded decrement.
 */
const shareDb = (postId: string, initialCount: number, existingUserIds: string[] = []) => {
  const state = {
    shares: new Map<string, boolean>(existingUserIds.map((userId) => [userId, true])),
    postSharesCount: initialCount,
  };
  const tx = {
    share: {
      findUnique: jest.fn().mockImplementation(({ where }: { where: { userId_postId: { postId: string; userId: string } } }) => {
        return state.shares.has(where.userId_postId.userId) ? { id: 'share-1' } : null;
      }),
      create: jest.fn().mockImplementation(({ data }: { data: { userId: string } }) => {
        state.shares.set(data.userId, true);
        return { id: 'share-new' };
      }),
      delete: jest.fn().mockImplementation(({ where }: { where: { userId_postId: { postId: string; userId: string } } }) => {
        state.shares.delete(where.userId_postId.userId);
        return { id: 'share-gone' };
      }),
    },
    post: {
      update: jest.fn().mockImplementation(({ data }: { data: { sharesCount: { increment: number } } }) => {
        state.postSharesCount += data.sharesCount.increment;
        return { sharesCount: state.postSharesCount };
      }),
      updateMany: jest.fn().mockImplementation(({ where, data }: {
        where: { sharesCount?: { gt: number } };
        data: { sharesCount: { decrement: number } };
      }) => {
        if (state.postSharesCount > (where.sharesCount?.gt ?? -1)) state.postSharesCount -= data.sharesCount.decrement;
        return { count: 1 };
      }),
      findUnique: jest.fn().mockImplementation(() => ({ sharesCount: state.postSharesCount })),
    },
  };
  return { state, tx };
};

const repositoryWith = async (tx: object) => {
  const module = await Test.createTestingModule({
    providers: [
      ShareDatabaseRepository,
      { provide: PrismaService, useValue: { $transaction: (work: (client: object) => Promise<unknown>) => work(tx) } },
    ],
  }).compile();
  return module.get(ShareDatabaseRepository);
};

describe('ShareDatabaseRepository.setPostShare', () => {
  it('creates the repost row and returns the fresh count when the post is not yet reposted', async () => {
    const { tx } = shareDb('post-1', 2);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostShare('user-1', 'post-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.share.create).toHaveBeenCalledTimes(1);
    expect(tx.post.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'post-1' },
      data: { sharesCount: { increment: 1 } },
    }));
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 3 });
  });

  it('does not double count when the user already reposted', async () => {
    const { state, tx } = shareDb('post-1', 2, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostShare('user-1', 'post-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.share.create).not.toHaveBeenCalled();
    expect(tx.post.update).not.toHaveBeenCalled();
    expect(state.postSharesCount).toBe(2);
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 2 });
  });

  it('removes the repost and returns the lowered fresh count', async () => {
    const { tx } = shareDb('post-1', 2, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostShare('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(tx.share.delete).toHaveBeenCalledTimes(1);
    expect(tx.post.updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'post-1', sharesCount: { gt: 0 } },
      data: { sharesCount: { decrement: 1 } },
    }));
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 1 });
  });

  it('keeps the count stable when un-sharing a post the user never reposted', async () => {
    const { state, tx } = shareDb('post-1', 2);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostShare('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(tx.share.delete).not.toHaveBeenCalled();
    expect(tx.post.updateMany).not.toHaveBeenCalled();
    expect(state.postSharesCount).toBe(2);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 2 });
  });

  it('never decrements below zero when the column is already floored', async () => {
    const { state, tx } = shareDb('post-1', 0, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostShare('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(state.postSharesCount).toBe(0);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 0 });
  });
});
