import { Test, TestingModule } from '@nestjs/testing';
import { StoryCleanupTask } from './story-cleanup.task';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockPrisma = {
  story: { deleteMany: jest.fn() },
};

describe('StoryCleanupTask', () => {
  let sut: StoryCleanupTask;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StoryCleanupTask,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<StoryCleanupTask>(StoryCleanupTask);
    jest.clearAllMocks();
  });

  it('should delete expired stories', async () => {
    mockPrisma.story.deleteMany.mockResolvedValue({ count: 5 });
    await sut.cleanupExpiredStories();
    expect(mockPrisma.story.deleteMany).toHaveBeenCalledWith({
      where: { expiresAt: { lt: expect.any(Date) } },
    });
  });

  it('should handle zero expired stories gracefully', async () => {
    mockPrisma.story.deleteMany.mockResolvedValue({ count: 0 });
    await sut.cleanupExpiredStories();
    expect(mockPrisma.story.deleteMany).toHaveBeenCalled();
  });
});
