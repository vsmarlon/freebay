import { Test } from "@nestjs/testing";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { PrismaPostRepository } from "./post-database.repository";
import { ContentFilter, FeedType } from "../../types/social.types";

const post = {
  id: "post-1",
  userId: "owner-1",
  type: "REGULAR",
  content: "post",
  imageUrl: null,
  productId: null,
  deletedAt: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  user: {
    id: "owner-1",
    displayName: "Owner",
    username: "owner",
    avatarUrl: null,
    isVerified: false,
  },
  likes: [{ userId: "other-user" }],
  savedBy: [{ userId: "other-user" }],
  shares: [{ userId: "other-user" }],
  _count: { likes: 1, comments: 0, shares: 1 },
  product: null,
};

describe("PrismaPostRepository canonical interactions", () => {
  it("uses the authenticated following query, block filters, and tied keyset metadata", async () => {
    const first = { ...post, id: "post-2", userId: "followed-1", createdAt: new Date("2026-09-12T00:00:00.000Z") };
    const second = { ...post, id: "post-1", userId: "followed-1", createdAt: first.createdAt };
    const findMany = jest.fn().mockResolvedValueOnce([first, second]);
    const followFindMany = jest.fn().mockResolvedValue([{ followingId: "followed-1" }]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        { provide: PrismaService, useValue: { post: { findMany }, follow: { findMany: followFindMany } } },
      ],
    }).compile();

    const result = await module.get(PrismaPostRepository).findFeed({
      userId: "viewer-1",
       type: FeedType.FOLLOWING,
       contentFilter: ContentFilter.SOCIAL,
      limit: 1,
    });

    expect(result.isRight()).toBe(true);
    expect(followFindMany).toHaveBeenCalledWith({
      where: { followerId: "viewer-1" },
      select: { followingId: true },
    });
    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      where: expect.objectContaining({
        type: "REGULAR",
        userId: { in: ["followed-1"] },
        AND: expect.arrayContaining([
          { user: { blocksGiven: { none: { blockedId: "viewer-1" } } } },
          { user: { blocksReceived: { none: { blockerId: "viewer-1" } } } },
        ]),
      }),
    }));
    if (result.isRight()) {
      expect(result.value.nextCursor).not.toBeNull();
      expect(Buffer.from(result.value.nextCursor!, "base64url").toString()).toBe(JSON.stringify({
        userId: "viewer-1",
        type: "following",
        contentFilter: "social",
        createdAt: first.createdAt.toISOString(),
        postId: "post-2",
        scope: "following-feed",
      }));
    }
  });

  it("pages equal timestamps by createdAt and id without overlap", async () => {
    const first = { ...post, id: "post-2", createdAt: new Date("2026-09-12T00:00:00.000Z") };
    const second = { ...post, id: "post-1", createdAt: first.createdAt };
    const findMany = jest
      .fn()
      .mockResolvedValueOnce([first, second])
      .mockResolvedValueOnce([second]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        { provide: PrismaService, useValue: { post: { findMany } } },
      ],
    }).compile();
    const repository = module.get(PrismaPostRepository);

    const result = await repository.findByUserId({ userId: "owner-1", limit: 1 });

    expect(result.isRight()).toBe(true);
    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({
      take: 2,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    }));
    if (result.isRight()) {
      expect(result.value.items.map((item) => item.id)).toEqual(["post-2"]);
      expect(result.value.hasMore).toBe(true);
      expect(result.value.nextCursor).not.toBeNull();
    }

    const next = await repository.findByUserId({
      userId: "owner-1",
      limit: 1,
      cursor: {
        scope: "user-posts",
        profileUserId: "owner-1",
        createdAt: first.createdAt.toISOString(),
        postId: first.id,
      },
    });

    expect(next.isRight()).toBe(true);
    expect(findMany).toHaveBeenLastCalledWith(expect.objectContaining({
      where: expect.objectContaining({
        OR: [
          { createdAt: { lt: first.createdAt } },
          { createdAt: first.createdAt, id: { lt: first.id } },
        ],
      }),
    }));
  });

  it("does not expose another user interaction as the viewer interaction", async () => {
    const findUnique = jest
      .fn()
      .mockResolvedValue({ ...post, likes: [], savedBy: [], shares: [] });
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        { provide: PrismaService, useValue: { post: { findUnique } } },
      ],
    }).compile();
    const repository = module.get(PrismaPostRepository);

    const result = await repository.findById("post-1", "viewer-1");

    expect(result.isRight()).toBe(true);
    if (result.isRight() && result.value) {
      expect(result.value.isLiked).toBe(false);
      expect(result.value.isSaved).toBe(false);
      expect(result.value.hasReposted).toBe(false);
      expect(result.value).not.toHaveProperty("likes");
      expect(result.value).not.toHaveProperty("savedBy");
      expect(result.value).not.toHaveProperty("shares");
    }
    expect(findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          likes: expect.objectContaining({ where: { userId: "viewer-1" } }),
          savedBy: expect.objectContaining({ where: { userId: "viewer-1" } }),
          shares: expect.objectContaining({ where: { userId: "viewer-1" } }),
        }),
      }),
    );
  });

  it("returns empty interaction relations for anonymous reads", async () => {
    const findUnique = jest
      .fn()
      .mockResolvedValue({ ...post, likes: [], savedBy: [], shares: [] });
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        { provide: PrismaService, useValue: { post: { findUnique } } },
      ],
    }).compile();
    const repository = module.get(PrismaPostRepository);

    const result = await repository.findById("post-1");

    expect(result.isRight()).toBe(true);
    if (result.isRight() && result.value) {
      expect(result.value.isLiked).toBe(false);
      expect(result.value.isSaved).toBe(false);
      expect(result.value.hasReposted).toBe(false);
    }
    expect(findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        include: expect.objectContaining({
          likes: expect.objectContaining({ where: { userId: "" } }),
          savedBy: expect.objectContaining({ where: { userId: "" } }),
          shares: expect.objectContaining({ where: { userId: "" } }),
        }),
      }),
    );
  });

  it("uses SavedPost.id for the next saved-page cursor", async () => {
    const findMany = jest
      .fn()
      .mockResolvedValueOnce([
        { id: "saved-1", post },
        { id: "saved-2", post: { ...post, id: "post-2" } },
        { id: "saved-3", post: { ...post, id: "post-3" } },
      ])
      .mockResolvedValueOnce([
        { id: "saved-3", post: { ...post, id: "post-3" } },
      ]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaPostRepository,
        { provide: PrismaService, useValue: { savedPost: { findMany } } },
      ],
    }).compile();
    const repository = module.get(PrismaPostRepository);

    const result = await repository.findSaved({ userId: "viewer-1", limit: 2 });
    const secondPage = await repository.findSaved({
      userId: "viewer-1",
      limit: 2,
      cursor: result.isRight()
        ? (result.value.nextCursor ?? undefined)
        : undefined,
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value.nextCursor).toBe("saved-2");
    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ take: 3 }));
    expect(secondPage.isRight()).toBe(true);
    expect(findMany).toHaveBeenLastCalledWith(
      expect.objectContaining({ cursor: { id: "saved-2" }, skip: 1 }),
    );
  });
});
