import { Test, TestingModule } from '@nestjs/testing';
import { CancelAccountDeletionUseCase } from './cancel-account-deletion.usecase';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';
import { left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError, UserNotFoundError } from '@/shared/core/errors';

const mockUserRepository = {
  findById: jest.fn(),
};

const mockAccountLifecycleRepository = {
  cancelDeletion: jest.fn(),
};

describe('CancelAccountDeletionUseCase', () => {
  let sut: CancelAccountDeletionUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CancelAccountDeletionUseCase,
        { provide: UserDatabaseRepository, useValue: mockUserRepository },
        { provide: AccountLifecycleDatabaseRepository, useValue: mockAccountLifecycleRepository },
      ],
    }).compile();

    sut = module.get(CancelAccountDeletionUseCase);

    mockUserRepository.findById.mockResolvedValue(
      right({ id: 'user-1', deletionRequestedAt: new Date('2026-01-01T00:00:00.000Z') }),
    );
    mockAccountLifecycleRepository.cancelDeletion.mockResolvedValue(right(undefined));
  });

  it('deve cancelar quando existe um pedido de exclusão pendente', async () => {
    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockAccountLifecycleRepository.cancelDeletion).toHaveBeenCalledWith('user-1');
  });

  it('deve retornar UserNotFoundError quando o usuário não existe', async () => {
    mockUserRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(UserNotFoundError);
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

  it('deve retornar BadRequestError quando não há exclusão pendente', async () => {
    mockUserRepository.findById.mockResolvedValue(
      right({ id: 'user-1', deletionRequestedAt: null }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

  it('deve propagar a falha quando a busca do usuário falha', async () => {
    mockUserRepository.findById.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });

  it('deve propagar a falha quando o cancelamento falha', async () => {
    mockAccountLifecycleRepository.cancelDeletion.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
