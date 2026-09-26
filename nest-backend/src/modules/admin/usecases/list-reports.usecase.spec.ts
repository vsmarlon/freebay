import { Test, TestingModule } from '@nestjs/testing';
import { ListReportsUseCase } from './list-reports.usecase';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { right } from '@/shared/core/either';
import { encodeCursor } from '@/shared/core/pagination';

const mockModerationRepository = {
  findReports: jest.fn(),
};

describe('ListReportsUseCase', () => {
  let sut: ListReportsUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ListReportsUseCase,
        { provide: ModerationDatabaseRepository, useValue: mockModerationRepository },
      ],
    }).compile();

    sut = module.get(ListReportsUseCase);

    mockModerationRepository.findReports.mockResolvedValue(
      right({ items: [], hasMore: false, nextCursor: null }),
    );
  });

  it('deve usar 20 como tamanho de página quando o limite não é informado', async () => {
    await sut.execute({});

    expect(mockModerationRepository.findReports).toHaveBeenCalledWith({
      status: undefined,
      cursorId: null,
      limit: 20,
    });
  });

  it('deve limitar a página a 50 quando pedem mais', async () => {
    await sut.execute({ limit: 500 });

    expect(mockModerationRepository.findReports.mock.calls[0][0].limit).toBe(50);
  });

  it('deve decodificar o id a partir do cursor opaco', async () => {
    await sut.execute({ cursor: encodeCursor({ id: 'report-9' }) });

    expect(mockModerationRepository.findReports.mock.calls[0][0].cursorId).toBe('report-9');
  });

  it('deve tratar um cursor inválido como primeira página', async () => {
    await sut.execute({ cursor: 'não-é-base64-json' });

    expect(mockModerationRepository.findReports.mock.calls[0][0].cursorId).toBeNull();
  });

  it('deve repassar o filtro de status', async () => {
    await sut.execute({ status: 'PENDING' });

    expect(mockModerationRepository.findReports.mock.calls[0][0].status).toBe('PENDING');
  });

});
