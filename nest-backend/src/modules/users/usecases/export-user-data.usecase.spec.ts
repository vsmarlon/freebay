import { Test, TestingModule } from '@nestjs/testing';
import { ExportUserDataUseCase } from './export-user-data.usecase';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';
import { right } from '@/shared/core/either';
import { UserNotFoundError } from '@/shared/core/errors';

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
        { provide: AccountLifecycleDatabaseRepository, useValue: mockAccountLifecycleRepository },
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

});
