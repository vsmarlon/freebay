import { Test, TestingModule } from '@nestjs/testing';
import { ResolveReportUseCase } from './resolve-report.usecase';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { left, right } from '@/shared/core/either';
import { ConflictError, DatabaseError, NotFoundError } from '@/shared/core/errors';

const mockModerationRepository = {
  findReportById: jest.fn(),
  resolveReport: jest.fn(),
  recordAction: jest.fn(),
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
    mockModerationRepository.resolveReport.mockResolvedValue(right({ count: 1 }));
    mockModerationRepository.recordAction.mockResolvedValue(right(undefined));
  });

  it('deve retornar NotFoundError quando a denúncia não existe', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(right(null));

    const result = await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'RESOLVED',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(NotFoundError);
    expect(mockModerationRepository.resolveReport).not.toHaveBeenCalled();
  });

  it('deve retornar ConflictError quando a denúncia já foi revisada', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(
      right(buildReport({ status: 'RESOLVED' })),
    );

    const result = await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'RESOLVED',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ConflictError);
    expect(mockModerationRepository.resolveReport).not.toHaveBeenCalled();
  });

  it('deve retornar ConflictError quando outro admin reivindicou a denúncia primeiro', async () => {
    mockModerationRepository.resolveReport.mockResolvedValue(right({ count: 0 }));

    const result = await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'RESOLVED',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ConflictError);
    expect(mockModerationRepository.recordAction).not.toHaveBeenCalled();
  });

  it('deve gravar quem resolveu a denúncia', async () => {
    await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'RESOLVED' });

    expect(mockModerationRepository.resolveReport).toHaveBeenCalledWith('report-1', {
      status: 'RESOLVED',
      reviewedById: 'admin-1',
    });
  });

  it('deve registrar a ação de moderação com a nota do admin', async () => {
    await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'RESOLVED',
      note: 'procede',
    });

    expect(mockModerationRepository.recordAction).toHaveBeenCalledWith({
      actorId: 'admin-1',
      targetType: 'REPORT',
      targetId: 'report-1',
      action: 'REPORT_RESOLVED',
      reason: 'procede',
      reportId: 'report-1',
    });
  });

  it('deve mapear REVIEWED para a ação REPORT_REVIEWED', async () => {
    await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'REVIEWED' });

    expect(mockModerationRepository.recordAction.mock.calls[0][0].action).toBe('REPORT_REVIEWED');
  });

  it('deve mapear REJECTED para a ação REPORT_REJECTED', async () => {
    await sut.execute({ reportId: 'report-1', adminId: 'admin-1', status: 'REJECTED' });

    expect(mockModerationRepository.recordAction.mock.calls[0][0].action).toBe('REPORT_REJECTED');
  });

  it('deve propagar a falha quando a busca da denúncia falha', async () => {
    mockModerationRepository.findReportById.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({
      reportId: 'report-1',
      adminId: 'admin-1',
      status: 'RESOLVED',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
