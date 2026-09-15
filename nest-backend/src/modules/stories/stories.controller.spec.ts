import { Test, TestingModule } from "@nestjs/testing";
import { Readable } from "node:stream";
import { left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import * as fileUtils from "@/shared/utils/file.utils";
import { StoriesController } from "./stories.controller";
import { StoriesService } from "./stories.service";
import { JwtAuthGuard } from "@/modules/auth/guards/jwt-auth.guard";
import { JwtTokenValidatorService } from "@/shared/auth/jwt-token-validator.service";

describe("StoriesController", () => {
  let sut: StoriesController;
  const service = { createStory: jest.fn() };
  const file: Express.Multer.File = {
    fieldname: "image",
    originalname: "story.jpg",
    encoding: "7bit",
    mimetype: "image/jpeg",
    size: 1,
    destination: "",
    filename: "story.jpg",
    path: "",
    buffer: Buffer.from([0xff, 0xd8, 0xff, 0xe0]),
    stream: Readable.from([]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StoriesController,
        { provide: StoriesService, useValue: service },
        { provide: JwtAuthGuard, useValue: { canActivate: jest.fn() } },
        { provide: JwtTokenValidatorService, useValue: { verifyAndValidate: jest.fn() } },
      ],
    }).compile();
    sut = module.get(StoriesController);
    service.createStory.mockReset();
  });

  it("removes the upload when story persistence fails", async () => {
    const deleteUpload = jest.spyOn(fileUtils, "deleteUpload");
    const saveUpload = jest.spyOn(fileUtils, "saveUpload").mockReturnValue(
      "/uploads/story/story-file.jpg",
    );
    service.createStory.mockResolvedValue(
      left(new AppError("STORY_CREATE_FAILED", "Não foi possível criar")),
    );

    const result = await sut.createStory("user-123", file);

    expect(result.isLeft()).toBe(true);
    expect(deleteUpload).toHaveBeenCalledWith("/uploads/story/story-file.jpg");
    deleteUpload.mockRestore();
    saveUpload.mockRestore();
  });

  it("keeps the upload when story persistence succeeds", async () => {
    const deleteUpload = jest.spyOn(fileUtils, "deleteUpload");
    const saveUpload = jest.spyOn(fileUtils, "saveUpload").mockReturnValue(
      "/uploads/story/story-file.jpg",
    );
    service.createStory.mockResolvedValue(right({ id: "story-123" }));

    const result = await sut.createStory("user-123", file);

    expect(result.isRight()).toBe(true);
    expect(deleteUpload).not.toHaveBeenCalled();
    deleteUpload.mockRestore();
    saveUpload.mockRestore();
  });
});
