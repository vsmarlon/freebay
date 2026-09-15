import { Test, TestingModule } from '@nestjs/testing';
import { GetDisputeUseCase } from './get-dispute.usecase';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockDisputeRepo = {
  findByIdWithDetails: jest.fn(),
};

describe('GetDisputeUseCase', () => {
  let sut: GetDisputeUseCase;

  const mockOrder = {
    id: 'order-123',
    buyerId: 'buyer-123',
    sellerId: 'seller-123',
  };

  const mockDispute = {
    id: 'dispute-123',
    orderId: 'order-123',
    openedById: 'buyer-123',
    reason: 'Product not as described',
    status: 'OPEN',
    createdAt: new Date(),
    order: { ...mockOrder, buyer: { id: 'buyer-123', displayName: 'Buyer', avatarUrl: null }, seller: { id: 'seller-123', displayName: 'Seller', avatarUrl: null }, product: {} },
    openedBy: { id: 'buyer-123', displayName: 'Buyer' },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GetDisputeUseCase, { provide: PrismaDisputeRepository, useValue: mockDisputeRepo }],
    }).compile();

    sut = module.get<GetDisputeUseCase>(GetDisputeUseCase);
    jest.clearAllMocks();
  });

  it('returns dispute when found', async () => {
    mockDisputeRepo.findByIdWithDetails.mockResolvedValue(right(mockDispute));

    const result = await sut.execute('dispute-123', 'buyer-123');

    expect(result.isRight()).toBe(true);
  });

  it('returns NotFoundError when dispute not found', async () => {
    mockDisputeRepo.findByIdWithDetails.mockResolvedValue(right(null));

    const result = await sut.execute('nonexistent', 'buyer-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('returns UnauthorizedError when user is not a participant', async () => {
    mockDisputeRepo.findByIdWithDetails.mockResolvedValue(right(mockDispute));

    const result = await sut.execute('dispute-123', 'stranger-123');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(UnauthorizedError);
    }
  });
});
