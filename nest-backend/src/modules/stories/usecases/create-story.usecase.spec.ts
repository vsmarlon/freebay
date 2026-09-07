import { Test, TestingModule } from '@nestjs/testing';
import { CreateStoryUseCase } from './create-story.usecase';
import { PrismaStoryRepository } from '../data/repositories/story-database.repository';
import { right } from '@/shared/core/either';

describe('CreateStoryUseCase', () => {
  let sut: CreateStoryUseCase;
  let mockStoryRepository: { create: jest.Mock };

  beforeEach(async () => {
    mockStoryRepository = {
      create: jest.fn().mockResolvedValue(right({
        id: 'story-123',
        userId: 'user-123',
        imageUrl: 'http://example.com/image.jpg',
        expiresAt: new Date(),
        createdAt: new Date(),
        user: {
          id: 'user-123',
          displayName: 'Test User',
          avatarUrl: null,
          isVerified: false,
        },
      })),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateStoryUseCase,
        { provide: PrismaStoryRepository, useValue: mockStoryRepository },
      ],
    }).compile();

    sut = module.get<CreateStoryUseCase>(CreateStoryUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should create a story', async () => {
    const input = {
      userId: 'user-123',
      imageUrl: 'base64encodedimage',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });
});
