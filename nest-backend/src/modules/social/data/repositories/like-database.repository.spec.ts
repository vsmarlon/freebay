import { Test } from '@nestjs/testing';
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { LikeDatabaseRepository } from "./like-database.repository";

/**
 * Minimal in-memory stand-in for the like table + Post.likesCount column so the
 * transaction's read-after-write behavior is observable without echoing the
 * implementation's SQL.
 */
const likeDb = (postId: string, initialCount: number, existingUserIds: string[] = []) => {
  const state = {
    likes: new Map<string, boolean>(existingUserIds.map((userId) => [userId, true])),
    postLikesCount: initialCount,
  };
  const tx = {
    like: {
      findUnique: jest.fn().mockImplementation(({ where }: { where: { userId_postId: { postId: string; userId: string } } }) => {
        return state.likes.has(where.userId_postId.userId) ? { id: 'like-1' } : null;
      }),
      create: jest.fn().mockImplementation(({ data }: { data: { userId: string } }) => {
        state.likes.set(data.userId, true);
        return { id: 'like-new' };
      }),
      delete: jest.fn().mockImplementation(({ where }: { where: { userId_postId: { postId: string; userId: string } } }) => {
        state.likes.delete(where.userId_postId.userId);
        return { id: 'like-gone' };
      }),
    },
    post: {
      update: jest.fn().mockImplementation(({ data }: { data: { likesCount: { increment: number } } }) => {
        state.postLikesCount += data.likesCount.increment;
        return { likesCount: state.postLikesCount };
      }),
      updateMany: jest.fn().mockImplementation(({ where, data }: {
        where: { likesCount?: { gt: number } };
        data: { likesCount: { decrement: number } };
      }) => {
        if (state.postLikesCount > (where.likesCount?.gt ?? -1)) state.postLikesCount -= data.likesCount.decrement;
        return { count: 1 };
      }),
      findUnique: jest.fn().mockImplementation(() => ({ likesCount: state.postLikesCount })),
    },
  };
  return { state, tx };
};

const repositoryWith = async (tx: object) => {
  const module = await Test.createTestingModule({
    providers: [
      LikeDatabaseRepository,
      { provide: PrismaService, useValue: { $transaction: (work: (client: object) => Promise<unknown>) => work(tx) } },
    ],
  }).compile();
  return module.get(LikeDatabaseRepository);
};

describe('LikeDatabaseRepository.setPostLike', () => {
  it('creates the like row and returns the fresh count when the post is not yet liked', async () => {
    const { tx } = likeDb('post-1', 3);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostLike('user-1', 'post-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.like.create).toHaveBeenCalledTimes(1);
    expect(tx.post.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'post-1' },
      data: { likesCount: { increment: 1 } },
    }));
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 4 });
  });

  it('does not double count when the user already liked the post', async () => {
    const { state, tx } = likeDb('post-1', 3, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostLike('user-1', 'post-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.like.create).not.toHaveBeenCalled();
    expect(tx.post.update).not.toHaveBeenCalled();
    expect(state.postLikesCount).toBe(3);
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 3 });
  });

  it('removes the like and returns the lowered fresh count', async () => {
    const { state, tx } = likeDb('post-1', 3, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostLike('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(tx.like.delete).toHaveBeenCalledTimes(1);
    expect(tx.post.updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'post-1', likesCount: { gt: 0 } },
      data: { likesCount: { decrement: 1 } },
    }));
    expect(state.postLikesCount).toBe(2);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 2 });
  });

  it('keeps the count stable when unliking a post the user never liked', async () => {
    const { state, tx } = likeDb('post-1', 3);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostLike('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(tx.like.delete).not.toHaveBeenCalled();
    expect(tx.post.updateMany).not.toHaveBeenCalled();
    expect(state.postLikesCount).toBe(3);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 3 });
  });

  it('never decrements below zero when the column is already floored', async () => {
    const { state, tx } = likeDb('post-1', 0, ['user-1']);
    const repository = await repositoryWith(tx);

    const result = await repository.setPostLike('user-1', 'post-1', false);

    expect(result.isRight()).toBe(true);
    expect(state.postLikesCount).toBe(0);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 0 });
  });

  it('round-trips like → unlike → like with the correct count after each step', async () => {
    const { state } = likeDb('post-1', 0);
    const tx = {
      like: {
        findUnique: ({ where }: { where: { userId_postId: { postId: string; userId: string } } }) =>
          state.likes.has(where.userId_postId.userId) ? { id: 'like-1' } : null,
        create: ({ data }: { data: { userId: string } }) => (state.likes.set(data.userId, true), { id: 'like-x' }),
        delete: ({ where }: { where: { userId_postId: { postId: string; userId: string } } }) =>
          (state.likes.delete(where.userId_postId.userId), { id: 'like-y' }),
      },
      post: {
        update: ({ data }: { data: { likesCount: { increment: number } } }) =>
          (state.postLikesCount += data.likesCount.increment, { likesCount: state.postLikesCount }),
        updateMany: ({ where, data }: { where: { likesCount?: { gt: number } }; data: { likesCount: { decrement: number } } }) => {
          if (state.postLikesCount > (where.likesCount?.gt ?? -1)) state.postLikesCount -= data.likesCount.decrement;
          return { count: 1 };
        },
        findUnique: () => ({ likesCount: state.postLikesCount }),
      },
    };
    const repository = await repositoryWith(tx);

    expect((await repository.setPostLike('user-1', 'post-1', true)).isRight() && state.postLikesCount).toBe(1);
    expect((await repository.setPostLike('user-1', 'post-1', false)).isRight() && state.postLikesCount).toBe(0);
    expect((await repository.setPostLike('user-1', 'post-1', true)).isRight() && state.postLikesCount).toBe(1);
  });
});
