import { Test } from "@nestjs/testing";
import { encodeCursor } from "@/shared/core/pagination";
import { PrismaPostRepository } from "../data/repositories/post-database.repository";
import { GetUserPostsUseCase } from "./get-user-posts.usecase";

describe("GetUserPostsUseCase", () => {
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

});
