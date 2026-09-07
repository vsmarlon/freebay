import { Test, TestingModule } from '@nestjs/testing';
import { GetWalletUseCase } from './get-wallet.usecase';
import { WalletDatabaseRepository } from '../data/repositories/wallet-database.repository';
import { right } from '@/shared/core/either';

describe('GetWalletUseCase', () => {
  let sut: GetWalletUseCase;
  let mockWalletRepository: { findByUserId: jest.Mock };

  beforeEach(async () => {
    mockWalletRepository = {
      findByUserId: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetWalletUseCase,
        { provide: WalletDatabaseRepository, useValue: mockWalletRepository },
      ],
    }).compile();

    sut = module.get(GetWalletUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return wallet with calculated available balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(right({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 8000,
      pendingBalance: 2000,
    }));

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.balance).toBe(10000);
      expect(result.value.pendingBalance).toBe(2000);
      expect(result.value.availableBalance).toBe(8000);
    }
  });

  it('should return zeros if wallet not found', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(right(null));

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.balance).toBe(0);
      expect(result.value.pendingBalance).toBe(0);
      expect(result.value.availableBalance).toBe(0);
    }
  });
});
