import { Test, TestingModule } from '@nestjs/testing';
import { ExportUserDataUseCase } from './export-user-data.usecase';
import { AccountLifecycleRepository } from '../domain/repositories/account-lifecycle.repository';
import { left, right } from '@/shared/core/either';
import { DatabaseError, UserNotFoundError } from '@/shared/core/errors';

const mockAccountLifecycleRepository = {
  exportData: jest.fn(),
};

describe('ExportUserDataUseCase', () => {
  let sut: ExportUserDataUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExportUserDataUseCase,
        { provide: AccountLifecycleRepository, useValue: mockAccountLifecycleRepository },
      ],
    }).compile();

    sut = module.get(ExportUserDataUseCase);
  });

  it('deve devolver o documento exportado quando o usuário existe', async () => {
    mockAccountLifecycleRepository.exportData.mockResolvedValue(
      right({ profile: { id: 'user-1' } }),
    );

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isRight()).toBe(true);
    expect(result.value).toEqual({ profile: { id: 'user-1' } });
    expect(mockAccountLifecycleRepository.exportData).toHaveBeenCalledWith('user-1');
  });

  it('deve retornar UserNotFoundError quando o repositório devolve null', async () => {
    mockAccountLifecycleRepository.exportData.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(UserNotFoundError);
  });

  it('deve propagar a falha quando a exportação falha', async () => {
    mockAccountLifecycleRepository.exportData.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ userId: 'user-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
