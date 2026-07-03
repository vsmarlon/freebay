import { Test, TestingModule } from '@nestjs/testing';
import { ResolveReportUseCase } from './resolve-report.usecase';
import { ReportRepository } from '../domain/repositories/report.repository';
import { NotFoundError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockRepo = {
  findReportById: jest.fn(),
  updateReport: jest.fn(),
  updateUser: jest.fn(),
};

describe('ResolveReportUseCase', () => {
  let sut: ResolveReportUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ResolveReportUseCase,
        { provide: ReportRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get<ResolveReportUseCase>(ResolveReportUseCase);
    jest.clearAllMocks();
  });

  it('should return error if report not found', async () => {
    mockRepo.findReportById.mockResolvedValue(right(null));
    const result = await sut.execute({ reportId: 'r-1', status: 'RESOLVED' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should resolve report and deactivate user verification', async () => {
    mockRepo.findReportById.mockResolvedValue(right({ id: 'r-1', reportedUserId: 'u-2' }));
    mockRepo.updateReport.mockResolvedValue(right({}));
    mockRepo.updateUser.mockResolvedValue(right({}));

    const result = await sut.execute({ reportId: 'r-1', status: 'RESOLVED' });
    expect(result.isRight()).toBe(true);
    expect(mockRepo.updateUser).toHaveBeenCalledWith('u-2', { isVerified: false });
  });

  it('should review report without deactivating verification', async () => {
    mockRepo.findReportById.mockResolvedValue(right({ id: 'r-1', reportedUserId: 'u-2' }));
    mockRepo.updateReport.mockResolvedValue(right({}));

    const result = await sut.execute({ reportId: 'r-1', status: 'REVIEWED' });
    expect(result.isRight()).toBe(true);
    expect(mockRepo.updateUser).not.toHaveBeenCalled();
  });

  it('should reject report without side effects', async () => {
    mockRepo.findReportById.mockResolvedValue(right({ id: 'r-1', reportedUserId: 'u-2' }));
    mockRepo.updateReport.mockResolvedValue(right({}));

    const result = await sut.execute({ reportId: 'r-1', status: 'REJECTED', adminNote: 'No violation found' });
    expect(result.isRight()).toBe(true);
    expect(mockRepo.updateUser).not.toHaveBeenCalled();
  });
});
