import { Test, TestingModule } from '@nestjs/testing';
import { GetWalletUseCase } from './get-wallet.usecase';
import { PrismaWalletRepository } from '../repositories/wallet.repository';

describe('GetWalletUseCase', () => {
  let sut: GetWalletUseCase;
  let mockWalletRepository: any;

  beforeEach(async () => {
    mockWalletRepository = {
      findByUserId: jest.fn(),
    } as jest.Mocked<Partial<PrismaWalletRepository>>;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetWalletUseCase,
        { provide: PrismaWalletRepository, useValue: mockWalletRepository },
      ],
    }).compile();

    sut = module.get<GetWalletUseCase>(GetWalletUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return wallet with calculated available balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 8000,
      pendingBalance: 2000,
    });

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.balance).toBe(10000);
      expect(result.value.pendingBalance).toBe(2000);
      expect(result.value.availableBalance).toBe(8000);
    }
  });

  it('should return zeros if wallet not found', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(null);

    const result = await sut.execute('user-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.balance).toBe(0);
      expect(result.value.pendingBalance).toBe(0);
      expect(result.value.availableBalance).toBe(0);
    }
  });
});
