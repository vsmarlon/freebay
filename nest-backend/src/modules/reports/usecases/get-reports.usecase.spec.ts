import { Test, TestingModule } from '@nestjs/testing';
import { GetReportsUseCase } from './get-reports.usecase';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';
import { right } from '@/shared/core/either';

const mockRepo = {
  findAllReports: jest.fn(),
};

describe('GetReportsUseCase', () => {
  let sut: GetReportsUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetReportsUseCase,
        { provide: ReportDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get<GetReportsUseCase>(GetReportsUseCase);
    jest.clearAllMocks();
  });

  it('should return all reports when no status filter', async () => {
    const now = new Date();
    mockRepo.findAllReports.mockResolvedValue(right([
      { id: 'r-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: now, reporterId: 'u-1', reportedUserId: 'u-2', reportedPostId: null },
      { id: 'r-2', reason: 'INAPPROPRIATE', description: 'Bad content', status: 'RESOLVED', createdAt: now, reporterId: 'u-1', reportedUserId: null, reportedPostId: 'p-1' },
    ]));

    const result = await sut.execute();
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toHaveLength(2);
  });

  it('should filter reports by status', async () => {
    mockRepo.findAllReports.mockResolvedValue(right([{ id: 'r-1' }]));

    const result = await sut.execute('PENDING');
    expect(result.isRight()).toBe(true);
    expect(mockRepo.findAllReports).toHaveBeenCalledWith({ status: 'PENDING' });
  });

  it('should return empty list when no reports', async () => {
    mockRepo.findAllReports.mockResolvedValue(right([]));
    const result = await sut.execute();
    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual([]);
  });
});
