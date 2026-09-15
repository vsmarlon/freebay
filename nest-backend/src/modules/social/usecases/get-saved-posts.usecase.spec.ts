import { Test } from "@nestjs/testing";
import { right } from "@/shared/core/either";
import { CursorPage } from "@/shared/core/pagination";
import { PrismaSavedPostRepository } from "../data/repositories/saved-post-database.repository";
import { PostResponse } from "../types/social.types";
import { GetSavedPostsUseCase } from "./get-saved-posts.usecase";

describe("GetSavedPostsUseCase", () => {
  it("returns a typed 4xx for a malformed cursor without querying", async () => {
    const findSaved = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        GetSavedPostsUseCase,
        { provide: PrismaSavedPostRepository, useValue: { findSaved } },
      ],
    }).compile();

    const result = await module.get(GetSavedPostsUseCase).execute({
      userId: "user-1",
      cursor: "not-a-cursor",
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.statusCode).toBe(400);
    expect(findSaved).not.toHaveBeenCalled();
  });

  it("rejects a cursor from another endpoint or user without querying", async () => {
    const findSaved = jest.fn();
    const module = await Test.createTestingModule({
      providers: [
        GetSavedPostsUseCase,
        { provide: PrismaSavedPostRepository, useValue: { findSaved } },
      ],
    }).compile();
    const useCase = module.get(GetSavedPostsUseCase);
    const cursor = Buffer.from(JSON.stringify({
      scope: "user-posts",
      userId: "other-user",
      createdAt: new Date().toISOString(),
      savedPostId: "saved-1",
    }), "utf8").toString("base64url");

    const result = await useCase.execute({ userId: "user-1", cursor });

    expect(result.isLeft()).toBe(true);
    expect(findSaved).not.toHaveBeenCalled();
  });

  it("passes an opaque saved-row cursor to the repository", async () => {
    const findSaved = jest.fn().mockResolvedValue(
      right<CursorPage<PostResponse>>({ items: [], hasMore: false, nextCursor: null }),
    );
    const module = await Test.createTestingModule({
      providers: [
        GetSavedPostsUseCase,
        { provide: PrismaSavedPostRepository, useValue: { findSaved } },
      ],
    }).compile();
    const useCase = module.get(GetSavedPostsUseCase);
    const cursor = Buffer.from(JSON.stringify({
      scope: "saved-posts",
      userId: "user-1",
      createdAt: "2026-01-01T00:00:00.000Z",
      savedPostId: "saved-1",
    }), "utf8").toString("base64url");

    await useCase.execute({ userId: "user-1", limit: 2, cursor });

    expect(findSaved).toHaveBeenCalledWith({
      userId: "user-1",
      limit: 2,
      cursor: {
        scope: "saved-posts",
        userId: "user-1",
        createdAt: "2026-01-01T00:00:00.000Z",
        savedPostId: "saved-1",
      },
    });
  });
});
