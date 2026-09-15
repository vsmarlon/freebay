import { Test, TestingModule } from "@nestjs/testing";
import { UnlikeCommentUseCase } from "./unlike-comment.usecase";
import { PrismaCommentRepository } from "../data/repositories/comment-database.repository";
import { right } from "@/shared/core/either";

describe("UnlikeCommentUseCase", () => {
  let useCase: UnlikeCommentUseCase;
  let mockCommentRepo: { setCommentLike: jest.Mock };

  beforeEach(async () => {
    mockCommentRepo = {
      setCommentLike: jest.fn().mockResolvedValue(right(undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UnlikeCommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepo },
      ],
    }).compile();

    useCase = module.get(UnlikeCommentUseCase);
  });

  it("atomically idempotently unlikes a comment", async () => {
    const result = await useCase.execute({ userId: "u-1", commentId: "c-1" });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.setCommentLike).toHaveBeenCalledWith(
      "u-1",
      "c-1",
      false,
    );
  });
});
