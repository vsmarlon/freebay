import { Test, TestingModule } from '@nestjs/testing';
import {
  ACCOUNT_DELETION_GRACE_DAYS,
  RequestAccountDeletionUseCase,
} from './request-account-deletion.usecase';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { AccountLifecycleRepository } from '../domain/repositories/account-lifecycle.repository';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { left, right } from '@/shared/core/either';
import {
  AccountDeletionBlockedError,
  DatabaseError,
  UserNotFoundError,
} from '@/shared/core/errors';

const mockUserRepository = {
  findById: jest.fn(),
};

const mockAccountLifecycleRepository = {
  findDeletionBlockers: jest.fn(),
  requestDeletion: jest.fn(),
};

const mockSessionRevoker = {
  revokeAllSessions: jest.fn(),
};

const noBlockers = {
  openOrdersAsBuyer: 0,
  openOrdersAsSeller: 0,
  openDisputes: 0,
  walletBalance: 0,
};

describe('RequestAccountDeletionUseCase', () => {
  let sut: RequestAccountDeletionUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RequestAccountDeletionUseCase,
        { provide: UserRepository, useValue: mockUserRepository },
        { provide: AccountLifecycleRepository, useValue: mockAccountLifecycleRepository },
        { provide: SessionRevokerService, useValue: mockSessionRevoker },
      ],
    }).compile();

    sut = module.get(RequestAccountDeletionUseCase);

    mockUserRepository.findById.mockResolvedValue(
      right({ id: 'user-1', deletionRequestedAt: null }),
    );
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(right(noBlockers));
    mockAccountLifecycleRepository.requestDeletion.mockImplementation((_id, requestedAt) =>
      Promise.resolve(right(requestedAt)),
    );
    mockSessionRevoker.revokeAllSessions.mockResolvedValue(undefined);
  });

  it('deve usar 30 dias como janela de carência', () => {
    expect(ACCOUNT_DELETION_GRACE_DAYS).toBe(30);
  });

  it('deve retornar UserNotFoundError quando o usuário não existe', async () => {
    mockUserRepository.findById.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(UserNotFoundError);
    expect(mockAccountLifecycleRepository.requestDeletion).not.toHaveBeenCalled();
  });

  it('deve propagar a falha quando a busca do usuário falha', async () => {
    mockUserRepository.findById.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
    expect(mockAccountLifecycleRepository.findDeletionBlockers).not.toHaveBeenCalled();
  });

  it('deve devolver o estado existente sem revogar sessões quando a exclusão já foi pedida', async () => {
    const requestedAt = new Date('2026-01-01T12:00:00.000Z');
    mockUserRepository.findById.mockResolvedValue(
      right({ id: 'user-1', deletionRequestedAt: requestedAt }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockAccountLifecycleRepository.requestDeletion).not.toHaveBeenCalled();
    expect(mockSessionRevoker.revokeAllSessions).not.toHaveBeenCalled();
  });

  it('deve calcular purgeAfter como a data do pedido mais 30 dias', async () => {
    const requestedAt = new Date('2026-01-01T12:00:00.000Z');
    mockAccountLifecycleRepository.requestDeletion.mockResolvedValue(right(requestedAt));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    const state = result.value as { deletionRequestedAt: Date; purgeAfter: Date };
    expect(state.deletionRequestedAt).toEqual(requestedAt);
    expect(state.purgeAfter.toISOString()).toBe('2026-01-31T12:00:00.000Z');
  });

  it('deve revogar todas as sessões quando a exclusão é aceita', async () => {
    await sut.execute({ userId: 'user-1' });

    expect(mockSessionRevoker.revokeAllSessions).toHaveBeenCalledWith('user-1');
  });

  it('deve bloquear quando há uma compra em andamento', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({ ...noBlockers, openOrdersAsBuyer: 1 }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(AccountDeletionBlockedError);
    expect((result.value as AccountDeletionBlockedError).message).toContain('1 compra(s)');
    expect(mockAccountLifecycleRepository.requestDeletion).not.toHaveBeenCalled();
  });

  it('deve bloquear quando há uma venda em andamento', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({ ...noBlockers, openOrdersAsSeller: 1 }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect((result.value as AccountDeletionBlockedError).message).toContain('1 venda(s)');
  });

  it('deve bloquear quando há uma disputa aberta', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({ ...noBlockers, openDisputes: 1 }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect((result.value as AccountDeletionBlockedError).message).toContain('1 disputa(s)');
  });

  it('deve bloquear quando o saldo da carteira é 1 centavo', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({ ...noBlockers, walletBalance: 1 }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect((result.value as AccountDeletionBlockedError).message).toContain('saldo na carteira');
  });

  it('deve aceitar quando o saldo da carteira é exatamente 0', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({ ...noBlockers, walletBalance: 0 }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(mockAccountLifecycleRepository.requestDeletion).toHaveBeenCalled();
  });

  it('deve listar todas as pendências juntas quando há mais de uma', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      right({
        openOrdersAsBuyer: 2,
        openOrdersAsSeller: 3,
        openDisputes: 1,
        walletBalance: 500,
      }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    const message = (result.value as AccountDeletionBlockedError).message;
    expect(message).toContain('2 compra(s)');
    expect(message).toContain('3 venda(s)');
    expect(message).toContain('1 disputa(s)');
    expect(message).toContain('saldo na carteira');
  });

  it('deve propagar a falha quando a checagem de pendências falha', async () => {
    mockAccountLifecycleRepository.findDeletionBlockers.mockResolvedValue(
      left(new DatabaseError('boom')),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
    expect(mockAccountLifecycleRepository.requestDeletion).not.toHaveBeenCalled();
  });

  it('não deve revogar sessões quando a gravação do pedido falha', async () => {
    mockAccountLifecycleRepository.requestDeletion.mockResolvedValue(
      left(new DatabaseError('boom')),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockSessionRevoker.revokeAllSessions).not.toHaveBeenCalled();
  });
});
