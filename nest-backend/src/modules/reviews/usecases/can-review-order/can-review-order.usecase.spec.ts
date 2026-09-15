import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CanReviewOrderUseCase } from './can-review-order.usecase';
import { OrderStatus, ReviewType, EscrowStatus } from '@prisma/client';
;
import type { CanReviewOrderUsecaseOutput } from './can-review-order.dto';

type MockPrisma = {
  order: { findUnique: jest.Mock };
  review: { findUnique: jest.Mock };
};

describe('CanReviewOrderUseCase', () => {
  let sut: CanReviewOrderUseCase;
  let mockPrisma: MockPrisma;

  const mockOrder = {
    id: 'order-1',
    buyerId: 'buyer-1',
    sellerId: 'seller-1',
    productId: 'product-1',
    amount: 10000,
    platformFee: 1000,
    sellerAmount: 9000,
    platformFeePercent: 10,
    status: OrderStatus.COMPLETED,
    escrowStatus: EscrowStatus.RELEASED,
    deliveryConfirmedAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    mockPrisma = {
      order: {
        findUnique: jest.fn(),
      },
      review: {
        findUnique: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CanReviewOrderUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get(CanReviewOrderUseCase);
  });

  describe('when order does not exist', () => {
    it('returns NOT_FOUND error', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'invalid-order',
        userId: 'user-1',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value.code).toBe('NOT_FOUND');
        expect(result.value.message).toContain('Order');
      }
    });
  });

  describe('when user is not part of the order', () => {
    it('returns canReview=false with reason', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'random-user',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(false);
        expect(value.reason).toBe('User is not part of this order');
      }
    });
  });

  describe('when order is not completed', () => {
    it('returns canReview=false with reason', async () => {
      const pendingOrder = { ...mockOrder, status: OrderStatus.PENDING };
      mockPrisma.order.findUnique.mockResolvedValue(pendingOrder);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'buyer-1',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(false);
        expect(value.reason).toBe('Order must be completed before reviewing');
      }
    });
  });

  describe('when buyer already reviewed seller', () => {
    it('returns canReview=false with reason', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue({
        id: 'review-1',
        reviewerId: 'buyer-1',
        reviewedId: 'seller-1',
        orderId: 'order-1',
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
        comment: 'Great seller',
        createdAt: new Date(),
      });

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'buyer-1',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(false);
        expect(value.reason).toBe('You have already reviewed this order');
      }
    });
  });

  describe('when buyer can review seller', () => {
    it('returns canReview=true with BUYER_REVIEWING_SELLER type', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'buyer-1',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(true);
        expect(value.reviewType).toBe(ReviewType.BUYER_REVIEWING_SELLER);
        expect(value.reason).toBeUndefined();
      }
    });
  });

  describe('when seller can review buyer', () => {
    it('returns canReview=true with SELLER_REVIEWING_BUYER type', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'seller-1',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(true);
        expect(value.reviewType).toBe(ReviewType.SELLER_REVIEWING_BUYER);
        expect(value.reason).toBeUndefined();
      }
    });
  });

  describe('when seller already reviewed buyer', () => {
    it('returns canReview=false with reason', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue({
        id: 'review-2',
        reviewerId: 'seller-1',
        reviewedId: 'buyer-1',
        orderId: 'order-1',
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 4,
        comment: 'Good buyer',
        createdAt: new Date(),
      });

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'seller-1',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const value = result.value as CanReviewOrderUsecaseOutput;
        expect(value.canReview).toBe(false);
        expect(value.reason).toBe('You have already reviewed this order');
      }
    });
  });
});
