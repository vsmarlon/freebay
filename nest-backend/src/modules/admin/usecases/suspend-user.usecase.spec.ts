import { Test, TestingModule } from '@nestjs/testing';
import { SuspendUserUseCase } from './suspend-user.usecase';
import { ModerationDatabaseRepository } from '../data/repositories/moderation-database.repository';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { left, right } from '@/shared/core/either';
import {
  BadRequestError,
  ConflictError,
  DatabaseError,
  UserNotFoundError,
} from '@/shared/core/errors';

const mockModerationRepository = {
  userExists: jest.fn(),
  setUserSuspension: jest.fn(),
  recordAction: jest.fn(),
};

const mockSessionRevoker = {
  revokeAllSessions: jest.fn(),
};

describe('SuspendUserUseCase', () => {
  let sut: SuspendUserUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SuspendUserUseCase,
        { provide: ModerationDatabaseRepository, useValue: mockModerationRepository },
        { provide: SessionRevokerService, useValue: mockSessionRevoker },
      ],
    }).compile();

    sut = module.get(SuspendUserUseCase);

    mockModerationRepository.userExists.mockResolvedValue(right(true));
    mockModerationRepository.setUserSuspension.mockResolvedValue(right({ count: 1 }));
    mockModerationRepository.recordAction.mockResolvedValue(right(undefined));
    mockSessionRevoker.revokeAllSessions.mockResolvedValue(undefined);
  });

  it('deve revogar as sessões ao suspender', async () => {
    const result = await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(result.isRight()).toBe(true);
    expect(mockSessionRevoker.revokeAllSessions).toHaveBeenCalledWith('user-1');
  });

  it('não deve revogar sessões ao reativar', async () => {
    await sut.execute({ targetUserId: 'user-1', adminId: 'admin-1', suspend: false });

    expect(mockSessionRevoker.revokeAllSessions).not.toHaveBeenCalled();
  });

  it('deve gravar a data e o motivo ao suspender', async () => {
    await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    const call = mockModerationRepository.setUserSuspension.mock.calls[0];
    expect(call[0]).toBe('user-1');
    expect(call[1].suspendedAt).toBeInstanceOf(Date);
    expect(call[1].suspensionReason).toBe('fraude');
  });

  it('deve limpar a data e o motivo ao reativar', async () => {
    await sut.execute({ targetUserId: 'user-1', adminId: 'admin-1', suspend: false });

    expect(mockModerationRepository.setUserSuspension).toHaveBeenCalledWith('user-1', {
      suspendedAt: null,
      suspensionReason: null,
    });
  });

  it('deve recusar um admin suspendendo a própria conta', async () => {
    const result = await sut.execute({
      targetUserId: 'admin-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockModerationRepository.setUserSuspension).not.toHaveBeenCalled();
  });

  it('deve retornar UserNotFoundError quando o usuário não existe', async () => {
    mockModerationRepository.userExists.mockResolvedValue(right(false));

    const result = await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(UserNotFoundError);
  });

  it('deve retornar ConflictError quando o usuário já está no estado pedido', async () => {
    mockModerationRepository.setUserSuspension.mockResolvedValue(right({ count: 0 }));

    const result = await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(ConflictError);
    expect(mockSessionRevoker.revokeAllSessions).not.toHaveBeenCalled();
  });

  it('deve registrar USER_SUSPENDED na trilha de auditoria', async () => {
    await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(mockModerationRepository.recordAction).toHaveBeenCalledWith({
      actorId: 'admin-1',
      targetType: 'USER',
      targetId: 'user-1',
      action: 'USER_SUSPENDED',
      reason: 'fraude',
    });
  });

  it('deve registrar USER_UNSUSPENDED ao reativar', async () => {
    await sut.execute({ targetUserId: 'user-1', adminId: 'admin-1', suspend: false });

    expect(mockModerationRepository.recordAction.mock.calls[0][0].action).toBe('USER_UNSUSPENDED');
  });

  it('deve propagar a falha quando a checagem do usuário falha', async () => {
    mockModerationRepository.userExists.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({
      targetUserId: 'user-1',
      adminId: 'admin-1',
      suspend: true,
      reason: 'fraude',
    });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
