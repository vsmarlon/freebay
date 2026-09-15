import { Test, TestingModule } from "@nestjs/testing";
import { right } from "@/shared/core/either";
import { PrismaShareRepository } from "../data/repositories/share-database.repository";
import { GetUserRepostsUseCase } from "./get-user-reposts.usecase";

describe("GetUserRepostsUseCase", () => {
  it("uses the repost cursor independently from owned posts", async () => {
    const shareRepository = {
      findPostsRepostedByUser: jest.fn().mockResolvedValue(right([])),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetUserRepostsUseCase,
        { provide: PrismaShareRepository, useValue: shareRepository },
      ],
    }).compile();

    const useCase = module.get(GetUserRepostsUseCase);
    const result = await useCase.execute({
      userId: "user-1",
      viewerId: "viewer-1",
      limit: 10,
      cursor: "share-cursor",
    });

    expect(result.isRight()).toBe(true);
    expect(shareRepository.findPostsRepostedByUser).toHaveBeenCalledWith(
      "user-1",
      { viewerId: "viewer-1", limit: 10, cursor: "share-cursor" },
    );
  });
});
