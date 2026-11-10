import { Test, TestingModule } from '@nestjs/testing';
import { CreateReportUseCase } from './create-report.usecase';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';
import { ReportReason, ReportTargetType } from '@prisma/client';

const mockRepo = {
  findUserById: jest.fn(),
  findPostById: jest.fn(),
  findConversationById: jest.fn(),
  findDirectMessageById: jest.fn(),
  findOrderById: jest.fn(),
  findChatMessageById: jest.fn(),
  findReportByUnique: jest.fn(),
  createReport: jest.fn(),
};

describe('CreateReportUseCase', () => {
  let sut: CreateReportUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateReportUseCase,
        { provide: ReportDatabaseRepository, useValue: mockRepo },
      ],
    }).compile();

    sut = module.get<CreateReportUseCase>(CreateReportUseCase);
    jest.clearAllMocks();
  });

  it('returns error if target user does not exist', async () => {
    mockRepo.findUserById.mockResolvedValue(right(null));
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.USER, targetId: 'user-1', reason: ReportReason.SPAM });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if user already reported', async () => {
    mockRepo.findUserById.mockResolvedValue(right({ id: 'user-1' }));
    mockRepo.findReportByUnique.mockResolvedValue(right({ id: 'report-1' }));
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.USER, targetId: 'user-1', reason: ReportReason.SPAM });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('creates a user report successfully', async () => {
    mockRepo.findUserById.mockResolvedValue(right({ id: 'user-1' }));
    mockRepo.findReportByUnique.mockResolvedValue(right(null));
    mockRepo.createReport.mockResolvedValue(right({ id: 'report-1', reporterId: 'reporter-1', reportedUserId: 'user-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: new Date() }));

    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.USER, targetId: 'user-1', reason: ReportReason.SPAM });
    expect(result.isRight()).toBe(true);
  });

  it('returns error if post does not exist', async () => {
    mockRepo.findPostById.mockResolvedValue(right(null));
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.POST, targetId: 'post-1', reason: ReportReason.SPAM });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('returns error if post already reported', async () => {
    mockRepo.findPostById.mockResolvedValue(right({ id: 'post-1' }));
    mockRepo.findReportByUnique.mockResolvedValue(right({ id: 'report-1' }));
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.POST, targetId: 'post-1', reason: ReportReason.SPAM });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('creates a post report successfully', async () => {
    mockRepo.findPostById.mockResolvedValue(right({ id: 'post-1' }));
    mockRepo.findReportByUnique.mockResolvedValue(right(null));
    mockRepo.createReport.mockResolvedValue(right({ id: 'report-2', reporterId: 'reporter-1', reportedPostId: 'post-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: new Date() }));

    const result = await sut.execute({ reporterId: 'reporter-1', targetType: ReportTargetType.POST, targetId: 'post-1', reason: ReportReason.SPAM });
    expect(result.isRight()).toBe(true);
  });

});
