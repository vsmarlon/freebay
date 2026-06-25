import { Test, TestingModule } from '@nestjs/testing';
import { ResolveReportUseCase } from './resolve-report.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError } from '@/shared/core/errors';

const mockPrisma = {
  report: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  user: { update: jest.fn() },
};

describe('ResolveReportUseCase', () => {
  let sut: ResolveReportUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ResolveReportUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<ResolveReportUseCase>(ResolveReportUseCase);
    jest.clearAllMocks();
  });

  it('should return error if report not found', async () => {
    mockPrisma.report.findUnique.mockResolvedValue(null);
    const result = await sut.execute({ reportId: 'r-1', status: 'RESOLVED' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
  });

  it('should resolve report and deactivate user verification', async () => {
    mockPrisma.report.findUnique.mockResolvedValue({ id: 'r-1', reportedUserId: 'u-2' });
    mockPrisma.report.update.mockResolvedValue({});
    mockPrisma.user.update.mockResolvedValue({});

    const result = await sut.execute({ reportId: 'r-1', status: 'RESOLVED' });
    expect(result.isRight()).toBe(true);
    expect(mockPrisma.user.update).toHaveBeenCalledWith({
      where: { id: 'u-2' },
      data: { isVerified: false },
    });
  });

  it('should review report without deactivating verification', async () => {
    mockPrisma.report.findUnique.mockResolvedValue({ id: 'r-1', reportedUserId: 'u-2' });
    mockPrisma.report.update.mockResolvedValue({});

    const result = await sut.execute({ reportId: 'r-1', status: 'REVIEWED' });
    expect(result.isRight()).toBe(true);
    expect(mockPrisma.user.update).not.toHaveBeenCalled();
  });

  it('should reject report without side effects', async () => {
    mockPrisma.report.findUnique.mockResolvedValue({ id: 'r-1', reportedUserId: 'u-2' });
    mockPrisma.report.update.mockResolvedValue({});

    const result = await sut.execute({ reportId: 'r-1', status: 'REJECTED', adminNote: 'No violation found' });
    expect(result.isRight()).toBe(true);
    expect(mockPrisma.user.update).not.toHaveBeenCalled();
  });
});
