import { Test, TestingModule } from '@nestjs/testing';
import { CreateReportUseCase } from './create-report.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';

const mockPrisma = {
  user: { findUnique: jest.fn() },
  post: { findUnique: jest.fn() },
  report: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
};

describe('CreateReportUseCase', () => {
  let sut: CreateReportUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateReportUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<CreateReportUseCase>(CreateReportUseCase);
    jest.clearAllMocks();
  });

  it('should return error if target user does not exist', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'USER', targetId: 'user-1', reason: 'SPAM' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if user already reported', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    mockPrisma.report.findUnique.mockResolvedValue({ id: 'report-1' });
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'USER', targetId: 'user-1', reason: 'SPAM' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should create a user report successfully', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    mockPrisma.report.findUnique.mockResolvedValue(null);
    mockPrisma.report.create.mockResolvedValue({ id: 'report-1', reporterId: 'reporter-1', reportedUserId: 'user-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: new Date() });

    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'USER', targetId: 'user-1', reason: 'SPAM' });
    expect(result.isRight()).toBe(true);
  });

  it('should return error if post does not exist', async () => {
    mockPrisma.post.findUnique.mockResolvedValue(null);
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'POST', targetId: 'post-1', reason: 'SPAM' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should return error if post already reported', async () => {
    mockPrisma.post.findUnique.mockResolvedValue({ id: 'post-1' });
    mockPrisma.report.findUnique.mockResolvedValue({ id: 'report-1' });
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'POST', targetId: 'post-1', reason: 'SPAM' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
  });

  it('should create a post report successfully', async () => {
    mockPrisma.post.findUnique.mockResolvedValue({ id: 'post-1' });
    mockPrisma.report.findUnique.mockResolvedValue(null);
    mockPrisma.report.create.mockResolvedValue({ id: 'report-2', reporterId: 'reporter-1', reportedPostId: 'post-1', reason: 'SPAM', description: null, status: 'PENDING', createdAt: new Date() });

    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'POST', targetId: 'post-1', reason: 'SPAM' });
    expect(result.isRight()).toBe(true);
  });

  it('should return error for invalid target type', async () => {
    const result = await sut.execute({ reporterId: 'reporter-1', targetType: 'COMMENT' as any, targetId: 'x', reason: 'SPAM' });
    expect(result.isLeft()).toBe(true);
  });
});
