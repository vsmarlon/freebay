import { Test, TestingModule } from '@nestjs/testing';
import { GetUserDisputesUseCase } from './get-user-disputes.usecase';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { right } from '@/shared/core/either';

const mockDisputeRepo = {
  findByUserId: jest.fn(),
};

describe('GetUserDisputesUseCase', () => {
  let sut: GetUserDisputesUseCase;

  const mockDispute = {
    id: 'dispute-123',
    orderId: 'order-123',
    openedById: 'buyer-123',
    reason: 'Product not as described',
    status: 'OPEN',
    createdAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GetUserDisputesUseCase, { provide: PrismaDisputeRepository, useValue: mockDisputeRepo }],
    }).compile();

    sut = module.get<GetUserDisputesUseCase>(GetUserDisputesUseCase);
    jest.clearAllMocks();
  });

  it('should return user disputes', async () => {
    mockDisputeRepo.findByUserId.mockResolvedValue(right([mockDispute]));

    const result = await sut.execute('buyer-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toHaveLength(1);
    }
  });
});
