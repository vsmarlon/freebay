import { Test, TestingModule } from '@nestjs/testing';
import { GetReportsUseCase } from './get-reports.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockPrisma = {
  report: { findMany: jest.fn() },
};

describe('GetReportsUseCase', () => {
  let sut: GetReportsUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetReportsUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<GetReportsUseCase>(GetReportsUseCase);
    jest.clearAllMocks();
  });

  it('should return all reports when no status filter', async () => {
    const now = new Date();
    mockPrisma.report.findMany.mockResolvedValue([
      { id: 'r-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: now, reporterId: 'u-1', reportedUserId: 'u-2', reportedPostId: null },
      { id: 'r-2', reason: 'INAPPROPRIATE', description: 'Bad content', status: 'RESOLVED', createdAt: now, reporterId: 'u-1', reportedUserId: null, reportedPostId: 'p-1' },
    ]);

    const result = await sut.execute();
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toHaveLength(2);
  });

  it('should filter reports by status', async () => {
    mockPrisma.report.findMany.mockResolvedValue([{ id: 'r-1' }]);

    const result = await sut.execute('PENDING');
    expect(result.isRight()).toBe(true);
    expect(mockPrisma.report.findMany).toHaveBeenCalledWith({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
    });
  });

  it('should return empty list when no reports', async () => {
    mockPrisma.report.findMany.mockResolvedValue([]);
    const result = await sut.execute();
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual([]);
  });
});
