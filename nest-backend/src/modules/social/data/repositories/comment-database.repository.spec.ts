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
