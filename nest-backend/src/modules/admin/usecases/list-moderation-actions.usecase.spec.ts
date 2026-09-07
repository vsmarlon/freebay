import { Test, TestingModule } from '@nestjs/testing';
import { ListModerationActionsUseCase } from './list-moderation-actions.usecase';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { encodeCursor } from '@/shared/core/pagination';

const mockModerationRepository = {
  findActions: jest.fn(),
};

describe('ListModerationActionsUseCase', () => {
  let sut: ListModerationActionsUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ListModerationActionsUseCase,
        { provide: ModerationDatabaseRepository, useValue: mockModerationRepository },
      ],
    }).compile();

    sut = module.get(ListModerationActionsUseCase);

    mockModerationRepository.findActions.mockResolvedValue(
      right({ items: [], hasMore: false, nextCursor: null }),
    );
  });

  it('deve usar 20 como tamanho de página quando o limite não é informado', async () => {
    await sut.execute({});

    expect(mockModerationRepository.findActions).toHaveBeenCalledWith({
      cursorId: null,
      limit: 20,
    });
  });

  it('deve decodificar o id a partir do cursor opaco', async () => {
    await sut.execute({ cursor: encodeCursor({ id: 'action-3' }) });

    expect(mockModerationRepository.findActions.mock.calls[0][0].cursorId).toBe('action-3');
  });

  it('deve propagar a falha do repositório', async () => {
    mockModerationRepository.findActions.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({});

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
