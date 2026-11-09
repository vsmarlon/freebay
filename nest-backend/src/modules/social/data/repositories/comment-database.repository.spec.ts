import { Test } from "@nestjs/testing";
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { CommentDatabaseRepository } from "./comment-database.repository";
import { CommentSort, CommentCursorScope } from '../../types/comment-cursor';

const comment = {
  id: "comment-1",
  content: "Comment",
  userId: "author-1",
  postId: "post-1",
  parentId: null,
  likesCount: 1,
  createdAt: new Date(),
  deletedAt: null,
  user: {
    id: "author-1",
    displayName: "Author",
    username: "author",
    avatarUrl: null,
  },
  _count: { commentLikes: 1 },
  commentLikes: [{ userId: "viewer-1" }],
};

describe("CommentDatabaseRepository viewer interactions", () => {
  it('removes uploaded comment files when the media-row transaction fails', async () => {
    const directory = join(process.cwd(), 'private-uploads', 'comment');
    const filesBefore = existsSync(directory) ? readdirSync(directory).sort() : [];
    const tx = {
      post: { findFirst: jest.fn().mockResolvedValue({ id: 'post-1', userId: 'owner-1', audience: 'EVERYONE', replyPermission: 'EVERYONE' }) },
      comment: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ ...comment, id: 'created-1', postId: 'post-1', deletedAt: null }),
      },
      user: { findMany: jest.fn().mockResolvedValue([]) },
      restriction: { findUnique: jest.fn().mockResolvedValue(null) },
      commentMedia: { create: jest.fn().mockRejectedValue(new Error('simulated media-row failure')) },
    };
    const module = await Test.createTestingModule({
      providers: [
        CommentDatabaseRepository,
        { provide: PrismaService, useValue: { $transaction: (work: (client: typeof tx) => Promise<unknown>) => work(tx) } },
      ],
    }).compile();
    const repository = module.get(CommentDatabaseRepository);

    const result = await repository.createIdempotent({ content: 'comment with file', post: { connect: { id: 'post-1' } }, user: { connect: { id: 'author-1' } } }, {
      postId: 'post-1', userId: 'author-1', requestId: 'request-1', digest: 'digest-1', mentionIds: [],
      media: [{ buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), mimetype: 'image/png', size: 8, sha256: 'a'.repeat(64) }],
    });

    expect(result.isLeft()).toBe(true);
    expect(tx.commentMedia.create).toHaveBeenCalledTimes(1);
    expect(existsSync(directory) ? readdirSync(directory).sort() : []).toEqual(filesBefore);
  });

  it("does not accept a pending ancestor as a continuation cursor", async () => {
    const focus = {
      ...comment,
      id: "focus-1",
      parentId: "pending-ancestor",
      commentLikes: [],
    };
    const findFirst = jest.fn()
      .mockResolvedValueOnce(focus)
      // Visibility filtering hides this pending node from the viewer.
      .mockResolvedValueOnce(null);
    const findMany = jest.fn().mockResolvedValue([]);
    const module = await Test.createTestingModule({
      providers: [
        CommentDatabaseRepository,
        { provide: PrismaService, useValue: { comment: { findFirst, findMany } } },
      ],
    }).compile();
    const repository = module.get(CommentDatabaseRepository);

    const result = await repository.findCommentContext(
      "focus-1", "viewer-1", 20, CommentSort.RECENT,
      undefined,
      { scope: CommentCursorScope.CONTEXT_ANCESTORS, ownerId: "focus-1", viewerId: "viewer-1", sort: CommentSort.RECENT, id: "pending-ancestor", createdAt: new Date().toISOString(), likesCount: 0 },
    );

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toBeNull();
    expect(findFirst).toHaveBeenCalledTimes(2);
  });

  it("filters comment likes by viewer and omits liker IDs", async () => {
    const findMany = jest.fn().mockResolvedValue([
      {
        ...comment,
        replies: [{ ...comment, id: "reply-1", parentId: "comment-1" }],
      },
    ]);
    const module = await Test.createTestingModule({
      providers: [
        CommentDatabaseRepository,
        { provide: PrismaService, useValue: { comment: { findMany } } },
      ],
    }).compile();
    const repository = module.get(CommentDatabaseRepository);

    const result = await repository.findAllByPostId(
      "post-1",
      "viewer-1",
    );

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(2);
      expect(result.value.every((entry) => entry.isLiked)).toBe(true);
      expect(result.value[0]).not.toHaveProperty("commentLikes");
      expect(result.value[1]).not.toHaveProperty("commentLikes");
    }
    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          commentLikes: expect.objectContaining({
            where: { userId: "viewer-1" },
          }),
          replies: expect.objectContaining({
            include: expect.objectContaining({
              commentLikes: expect.objectContaining({
                where: { userId: "viewer-1" },
              }),
            }),
          }),
        }),
      }),
    );
  });
});

describe("CommentDatabaseRepository.setCommentLike", () => {
  const likeTx = (params: {
    likesCount: number;
    visible?: boolean;
    createCount?: number;
  }) => {
    const state = { likesCount: params.likesCount };
    const calls = {
      createMany: [] as Array<object>,
      update: [] as Array<object>,
      deleteMany: [] as Array<object>,
      updateMany: [] as Array<object>,
    };
    const tx = {
      comment: {
        findFirst: jest.fn().mockResolvedValue(params.visible === false ? null : { id: 'comment-1' }),
        update: jest.fn().mockImplementation(({ data }: { data: { likesCount: { increment: number } } }) => {
          calls.update.push(data);
          state.likesCount += data.likesCount.increment;
          return { likesCount: state.likesCount };
        }),
        updateMany: jest.fn().mockImplementation(({ where, data }: {
          where: { likesCount?: { gt: number } };
          data: { likesCount: { decrement: number } };
        }) => {
          calls.updateMany.push(where);
          if (state.likesCount > (where.likesCount?.gt ?? -1)) state.likesCount -= data.likesCount.decrement;
          return { count: 1 };
        }),
        findUnique: jest.fn().mockImplementation(() => ({ likesCount: state.likesCount })),
      },
      commentLike: {
        createMany: jest.fn().mockImplementation((input: { data: { userId: string; commentId: string } }) => {
          calls.createMany.push(input);
          return Promise.resolve({ count: params.createCount ?? 1 });
        }),
        deleteMany: jest.fn().mockImplementation((input: { where: { userId: string; commentId: string } }) => {
          calls.deleteMany.push(input);
          return Promise.resolve({ count: params.createCount === undefined ? 1 : 0 });
        }),
      },
    };
    return { state, calls, tx };
  };

  const repositoryWith = async (tx: object) => {
    const module = await Test.createTestingModule({
      providers: [
        CommentDatabaseRepository,
        { provide: PrismaService, useValue: { $transaction: (work: (client: object) => Promise<unknown>) => work(tx) } },
      ],
    }).compile();
    return module.get(CommentDatabaseRepository);
  };

  it('likes an eligible comment once and returns the fresh count', async () => {
    const { state, tx } = likeTx({ likesCount: 3 });
    const repository = await repositoryWith(tx);

    const result = await repository.setCommentLike('user-1', 'comment-1', true);

    expect(result.isRight()).toBe(true);
    expect(tx.commentLike.createMany).toHaveBeenCalledWith({ data: { userId: 'user-1', commentId: 'comment-1' }, skipDuplicates: true });
    expect(state.likesCount).toBe(4);
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 4 });
  });

  it('does not double count a comment the user already liked', async () => {
    const { state, calls, tx } = likeTx({ likesCount: 3, createCount: 0 });
    const repository = await repositoryWith(tx);

    const result = await repository.setCommentLike('user-1', 'comment-1', true);

    expect(result.isRight()).toBe(true);
    expect(state.likesCount).toBe(3);
    expect(calls.update).toHaveLength(0);
    if (result.isRight()) expect(result.value).toEqual({ active: true, count: 3 });
  });

  it('skips the like write entirely for an invisible comment', async () => {
    const { state, calls, tx } = likeTx({ likesCount: 3, visible: false });
    const repository = await repositoryWith(tx);

    const result = await repository.setCommentLike('user-1', 'comment-1', true);

    expect(result.isRight()).toBe(true);
    expect(state.likesCount).toBe(3);
    expect(calls.createMany).toHaveLength(0);
    if (result.isRight()) expect(result.value).toBeNull();
  });

  it('unlike only decrements when a like row was removed', async () => {
    const { state, calls, tx } = likeTx({ likesCount: 2 });
    const repository = await repositoryWith(tx);

    const result = await repository.setCommentLike('user-1', 'comment-1', false);

    expect(result.isRight()).toBe(true);
    expect(calls.updateMany).toHaveLength(1);
    expect(state.likesCount).toBe(1);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 1 });
  });

  it('unlike without a like row keeps the count stable', async () => {
    const { state, calls, tx } = likeTx({ likesCount: 2 });
    const repository = await repositoryWith(tx);
    (tx.commentLike.deleteMany as jest.Mock).mockResolvedValue({ count: 0 });

    const result = await repository.setCommentLike('user-1', 'comment-1', false);

    expect(result.isRight()).toBe(true);
    expect(calls.updateMany).toHaveLength(0);
    expect(state.likesCount).toBe(2);
    if (result.isRight()) expect(result.value).toEqual({ active: false, count: 2 });
  });
});

describe("CommentDatabaseRepository.createIdempotent comment counting", () => {
  const baseTx = (params: { commentsCount: number; restricted?: boolean }) => {
    const state = { postCommentsCount: params.commentsCount };
    const tx = {
      post: {
        findFirst: jest.fn().mockResolvedValue({ id: 'post-1', userId: 'owner-1', audience: 'EVERYONE', replyPermission: 'EVERYONE' }),
        update: jest.fn().mockImplementation(({ data }: { data: { commentsCount: { increment: number } } }) => {
          state.postCommentsCount += data.commentsCount.increment;
          return { commentsCount: state.postCommentsCount };
        }),
        findUniqueOrThrow: jest.fn().mockImplementation(() => ({ commentsCount: state.postCommentsCount })),
      },
      comment: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ ...comment, id: 'created-1', media: [] }),
      },
      user: { findMany: jest.fn().mockResolvedValue([]) },
      restriction: {
        findUnique: jest.fn().mockResolvedValue(params.restricted ? { ownerId: 'owner-1' } : null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      commentSubscription: { findMany: jest.fn().mockResolvedValue([]) },
      commentConversationMute: { findMany: jest.fn().mockResolvedValue([]) },
      block: { findMany: jest.fn().mockResolvedValue([]) },
      notification: { createManyAndReturn: jest.fn().mockResolvedValue([]) },
    };
    return { state, tx };
  };

  const repositoryWith = async (tx: object) => {
    const module = await Test.createTestingModule({
      providers: [
        CommentDatabaseRepository,
        { provide: PrismaService, useValue: { $transaction: (work: (client: object) => Promise<unknown>) => work(tx) } },
      ],
    }).compile();
    return module.get(CommentDatabaseRepository);
  };

  const create = (repository: CommentDatabaseRepository) =>
    repository.createIdempotent(
      { content: 'nice', post: { connect: { id: 'post-1' } }, user: { connect: { id: 'user-1' } } },
      { postId: 'post-1', userId: 'user-1', requestId: 'req-1', digest: 'd', mentionIds: [] },
    );

  it('increments commentsCount only once for a first visible comment and reports the fresh count', async () => {
    const { state, tx } = baseTx({ commentsCount: 5 });
    const repository = await repositoryWith(tx);

    const result = await create(repository);

    expect(result.isRight()).toBe(true);
    expect(tx.post.update).toHaveBeenCalledTimes(1);
    expect(state.postCommentsCount).toBe(6);
    if (result.isRight()) expect(result.value.commentsCount).toBe(6);
  });

  it('does not increment commentsCount for a hidden (restricted) comment and reports the unchanged count', async () => {
    const { state, tx } = baseTx({ commentsCount: 5, restricted: true });
    const repository = await repositoryWith(tx);

    const result = await create(repository);

    expect(result.isRight()).toBe(true);
    expect(tx.post.update).not.toHaveBeenCalled();
    expect(state.postCommentsCount).toBe(5);
    if (result.isRight()) expect(result.value.commentsCount).toBe(5);
  });
});
