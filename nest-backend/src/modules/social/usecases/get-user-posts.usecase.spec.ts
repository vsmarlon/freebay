import { Test, TestingModule } from "@nestjs/testing";
import { right } from "@/shared/core/either";
import { encodeCursor } from "@/shared/core/pagination";
import { PrismaPostRepository } from "../data/repositories/post-database.repository";
import { GetUserPostsUseCase } from "./get-user-posts.usecase";

describe("GetUserPostsUseCase", () => {
  it("returns only posts owned by the requested user", async () => {
    const postRepository = {
      findByUserId: jest.fn().mockResolvedValue(right({
        items: [],
        hasMore: false,
        nextCursor: null,
      })),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetUserPostsUseCase,
        { provide: PrismaPostRepository, useValue: postRepository },
      ],
    }).compile();

    const useCase = module.get(GetUserPostsUseCase);
    const result = await useCase.execute({ userId: "user-1", limit: 10 });

    expect(result.isRight()).toBe(true);
    expect(postRepository.findByUserId).toHaveBeenCalledWith({
      userId: "user-1",
      limit: 10,
      viewerId: undefined,
      cursor: undefined,
    });
  });

  it.each([
    ["malformed", "not-base64"],
    ["wrong scope", encodeCursor({
      scope: "feed",
      profileUserId: "user-1",
      createdAt: "2026-09-12T00:00:00.000Z",
      postId: "post-1",
    })],
    ["wrong profile", encodeCursor({
      scope: "user-posts",
      profileUserId: "user-2",
      createdAt: "2026-09-12T00:00:00.000Z",
      postId: "post-1",
    })],
  ])("rejects a %s cursor without restarting", async (_, cursor) => {
    const postRepository = { findByUserId: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        GetUserPostsUseCase,
        { provide: PrismaPostRepository, useValue: postRepository },
      ],
    }).compile();

    const result = await module.get(GetUserPostsUseCase).execute({
      userId: "user-1",
      cursor,
    });

    expect(result.isLeft()).toBe(true);
    expect(postRepository.findByUserId).not.toHaveBeenCalled();
  });

  it("returns authoritative page metadata", async () => {
    const postRepository = {
      findByUserId: jest.fn().mockResolvedValue(right({
        items: [],
        hasMore: true,
        nextCursor: "next",
      })),
    };
    const module = await Test.createTestingModule({
      providers: [
        GetUserPostsUseCase,
        { provide: PrismaPostRepository, useValue: postRepository },
      ],
    }).compile();

    const result = await module.get(GetUserPostsUseCase).execute({
      userId: "user-1",
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.hasMore).toBe(true);
      expect(result.value.nextCursor).toBe("next");
    }
  });
});
