import { Test, TestingModule } from "@nestjs/testing";
import { LikeCommentUseCase } from "./like-comment.usecase";
import { PrismaCommentRepository } from "../data/repositories/comment-database.repository";
import { right } from "@/shared/core/either";

describe("LikeCommentUseCase", () => {
  let useCase: LikeCommentUseCase;
  let mockCommentRepo: { setCommentLike: jest.Mock };

  beforeEach(async () => {
    mockCommentRepo = {
      setCommentLike: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LikeCommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepo },
      ],
    }).compile();

    useCase = module.get(LikeCommentUseCase);
  });

  it("atomically idempotently likes a comment", async () => {
    const result = await useCase.execute({ userId: "u-1", commentId: "c-1" });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.setCommentLike).toHaveBeenCalledWith(
      "u-1",
      "c-1",
      true,
    );
  });
});
