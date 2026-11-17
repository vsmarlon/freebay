import { Test, TestingModule } from '@nestjs/testing';
import { ResolveReportUseCase } from './resolve-report.usecase';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { left, right } from '@/shared/core/either';
import { ConflictError, DatabaseError, NotFoundError } from '@/shared/core/errors';

const mockModerationRepository = {
  findReportById: jest.fn(),
  resolveReportAndRecord: jest.fn(),
};

const buildReport = (overrides: Record<string, unknown> = {}) => ({
  id: 'report-1',
  targetType: 'USER',
  reason: 'FRAUD',
  description: null,
  status: 'PENDING',
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  reviewedAt: null,
  reviewedById: null,
  reportedPostId: null,
  reportedDirectConversationId: null,
  reportedOrderChatId: null,
  reportedDirectMessageId: null,
  reportedChatMessageId: null,
  reporter: {
    id: 'reporter-1',
    displayName: 'Reporter',
    username: null,
    avatarUrl: null,
    suspendedAt: null,
  },
  reportedUser: {
    id: 'reported-1',
    displayName: 'Reported',
    username: null,
    avatarUrl: null,
    suspendedAt: null,
  },
  ...overrides,
});

describe('ResolveReportUseCase', () => {
  let sut: ResolveReportUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ResolveReportUseCase,
        { provide: ModerationDatabaseRepository, useValue: mockModerationRepository },
      ],
    }).compile();

    sut = module.get(ResolveReportUseCase);

    mockModerationRepository.findReportById.mockResolvedValue(right(buildReport()));
    mockModerationRepository.resolveReportAndRecord.mockResolvedValue(true);
  });

  it('retorna NotFoundError quando a denúncia não existe', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(right(null));

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
    expect(mockModerationRepository.resolveReportAndRecord).not.toHaveBeenCalled();
  });

  it('retorna ConflictError quando a denúncia já está em estado terminal', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(right(buildReport({ status: 'RESOLVED' })));

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ConflictError);
    expect(mockModerationRepository.resolveReportAndRecord).not.toHaveBeenCalled();
  });

  it('resolve uma denúncia legada em REVIEWED em vez de deixá-la presa', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(right(buildReport({ status: 'REVIEWED' })));

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isRight()).toBe(true);
    expect(mockModerationRepository.resolveReportAndRecord).toHaveBeenCalledWith({
      reportId: 'report-1',
      status: 'RESOLVED',
      adminId: 'admin-1',
      action: 'REPORT_RESOLVED',
      note: null,
    });
  });

  it('retorna ConflictError quando outro admin reivindicou a denúncia primeiro', async () => {
    mockModerationRepository.resolveReportAndRecord.mockResolvedValue(false);

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ConflictError);
  });

  it('grava a decisão e a auditoria na mesma chamada transacional', async () => {
    await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'REJECTED',
      note: 'sem indícios',
    });

    expect(mockModerationRepository.resolveReportAndRecord).toHaveBeenCalledWith({
      reportId: 'report-1',
      status: 'REJECTED',
      adminId: 'admin-1',
      action: 'REPORT_REJECTED',
      note: 'sem indícios',
    });
  });

  it('retorna DatabaseError quando a transação de resolução falha', async () => {
    mockModerationRepository.resolveReportAndRecord.mockRejectedValue(new Error('audit insert failed'));

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });

  it('propaga a falha da busca da denúncia', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
