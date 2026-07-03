import { Test, TestingModule } from '@nestjs/testing';
import { CreateBugReportUseCase } from './create-bug-report.usecase';
import { BugReportRepository } from '../domain/repositories/bug-report.repository';
import { AppError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

const mockRepo = {
  create: jest.fn(),
};

describe('CreateBugReportUseCase', () => {
  let sut: CreateBugReportUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateBugReportUseCase,
        { provide: BugReportRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get<CreateBugReportUseCase>(CreateBugReportUseCase);
    jest.clearAllMocks();
  });

  it('should create a bug report successfully', async () => {
    const bugReport = {
      id: 'bug-1',
      userId: 'user-1',
      description: 'App crashes',
      appVersion: null,
      platform: null,
      screenContext: null,
      createdAt: new Date(),
    };
    mockRepo.create.mockResolvedValue(right(bugReport));

    const result = await sut.execute({ userId: 'user-1', description: 'App crashes' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual(bugReport);
    expect(mockRepo.create).toHaveBeenCalledWith({ userId: 'user-1', description: 'App crashes' });
  });

  it('should return error when repository fails', async () => {
    mockRepo.create.mockResolvedValue(left(new AppError('DB_ERROR', 'Erro ao registrar relatório de bug')));

    const result = await sut.execute({ userId: 'user-1', description: 'App crashes' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(AppError);
  });
});
