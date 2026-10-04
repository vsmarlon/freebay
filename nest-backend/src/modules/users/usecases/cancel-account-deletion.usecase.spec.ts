import { Test, TestingModule } from '@nestjs/testing';
import { CancelAccountDeletionUseCase } from './cancel-account-deletion.usecase';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';
import { right } from '@/shared/core/either';
import { BadRequestError, UserNotFoundError } from '@/shared/core/errors';

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
    const input = { userId: 'user-1', authenticatedAtMs: Date.now() };
    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(mockAccountLifecycleRepository.cancelDeletion).toHaveBeenCalledWith('user-1');
  });

  it('rejects an old authenticated session even when a deletion is pending', async () => {
    const input = { userId: 'user-1', authenticatedAtMs: Date.now() - 6 * 60 * 1000 };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    expect(result.value).toMatchObject({ code: 'FRESH_AUTH_REQUIRED', statusCode: 401 });
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

  it('does not treat a missing auth-time claim as fresh', async () => {
    const input = { userId: 'user-1', authenticatedAtMs: null };
    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    expect(result.value).toMatchObject({ code: 'FRESH_AUTH_REQUIRED', statusCode: 401 });
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

  it('deve retornar UserNotFoundError quando o usuário não existe', async () => {
    mockUserRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-1', authenticatedAtMs: Date.now() });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(UserNotFoundError);
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

  it('deve retornar BadRequestError quando não há exclusão pendente', async () => {
    mockUserRepository.findById.mockResolvedValue(
      right({ id: 'user-1', deletionRequestedAt: null }),
    );

    const result = await sut.execute({ userId: 'user-1', authenticatedAtMs: Date.now() });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockAccountLifecycleRepository.cancelDeletion).not.toHaveBeenCalled();
  });

});
