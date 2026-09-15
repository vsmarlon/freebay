import { Test } from "@nestjs/testing";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { PrismaCommentRepository } from "./comment-database.repository";

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

describe("PrismaCommentRepository viewer interactions", () => {
  it("filters comment likes by viewer and omits liker IDs", async () => {
    const findMany = jest.fn().mockResolvedValue([
      {
        ...comment,
        replies: [{ ...comment, id: "reply-1", parentId: "comment-1" }],
      },
    ]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaCommentRepository,
        { provide: PrismaService, useValue: { comment: { findMany } } },
      ],
    }).compile();
    const repository = module.get(PrismaCommentRepository);

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
