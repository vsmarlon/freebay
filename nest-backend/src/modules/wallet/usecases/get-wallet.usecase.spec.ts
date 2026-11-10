import { Test, TestingModule } from '@nestjs/testing';
import { GetWalletUseCase } from './get-wallet.usecase';
import { WalletRepository } from '../domain/repositories/wallet.repository';
import { right } from '@/shared/core/either';

describe('GetWalletUseCase', () => {
  let sut: GetWalletUseCase;
  let mockWalletRepository: { ensureForUser: jest.Mock };

  beforeEach(async () => {
    mockWalletRepository = {
      ensureForUser: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetWalletUseCase,
        { provide: WalletRepository, useValue: mockWalletRepository },
      ],
    }).compile();

    sut = module.get(GetWalletUseCase);
  });

  it('returns wallet with calculated available balance', async () => {
    mockWalletRepository.ensureForUser.mockResolvedValue(right({
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

  it('returns zeros if wallet not found', async () => {
    mockWalletRepository.ensureForUser.mockResolvedValue(right({
      id: 'wallet-123', userId: 'user-123', availableBalance: 0, pendingBalance: 0, totalEarned: 0,
    }));

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.balance).toBe(0);
      expect(result.value.pendingBalance).toBe(0);
      expect(result.value.availableBalance).toBe(0);
    }
  });
});
