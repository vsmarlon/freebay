import { Test, TestingModule } from "@nestjs/testing";
import { CreateStoryUseCase } from "./create-story.usecase";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";
import { right } from "@/shared/core/either";
import { parseStoryTextBlocks } from "../dtos/stories.dto";

describe("CreateStoryUseCase", () => {
  let sut: CreateStoryUseCase;
  let mockStoryRepository: { create: jest.Mock };

  beforeEach(async () => {
    mockStoryRepository = {
      create: jest.fn().mockResolvedValue(
        right({
          id: "story-123",
          userId: "user-123",
          imageUrl: "http://example.com/image.jpg",
          mediaType: "IMAGE",
          caption: "caption",
          expiresAt: new Date(),
          createdAt: new Date(),
          user: {
            id: "user-123",
            displayName: "Test User",
            avatarUrl: null,
            isVerified: false,
          },
        }),
      ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateStoryUseCase,
        { provide: PrismaStoryRepository, useValue: mockStoryRepository },
      ],
    }).compile();

    sut = module.get<CreateStoryUseCase>(CreateStoryUseCase);
  });

  it("creates a story", async () => {
    const input = {
      userId: "user-123",
      imageUrl: "base64encodedimage",
      caption: "caption",
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockStoryRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        caption: "caption",
      }),
    );
  });

  it("validates and orders text blocks at the multipart boundary", () => {
    const result = parseStoryTextBlocks(
      JSON.stringify([
        {
          id: "second",
          text: " B ",
          x: 0.5,
          y: 0.5,
          scale: 1,
          rotation: 0,
          color: 0xffffffff,
          style: "strong",
          zIndex: 1,
        },
        {
          id: "first",
          text: "A",
          x: 0,
          y: 1,
          scale: 0.5,
          rotation: 0,
          color: 0,
          style: "classic",
          zIndex: 0,
        },
      ]),
    );

    expect("value" in result && result.value.map((block) => block.id)).toEqual([
      "first",
      "second",
    ]);
    expect("value" in result && result.value[1].text).toBe("B");
  });

  it("rejects duplicate IDs and unsupported styles", () => {
    const result = parseStoryTextBlocks([
      {
        id: "same",
        text: "A",
        x: 0.5,
        y: 0.5,
        scale: 1,
        rotation: 0,
        color: 0,
        style: "classic",
        zIndex: 0,
      },
      {
        id: "same",
        text: "B",
        x: 0.5,
        y: 0.5,
        scale: 1,
        rotation: 0,
        color: 0,
        style: "unknown",
        zIndex: 1,
      },
    ]);

    expect("error" in result).toBe(true);
  });
});
