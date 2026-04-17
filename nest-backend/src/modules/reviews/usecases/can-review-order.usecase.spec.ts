import { CanReviewOrderUseCase } from './can-review-order.usecase';
import { OrderStatus, ReviewType, EscrowStatus } from '@prisma/client';
import { isLeft, isRight } from '@/shared/core/either';

describe('CanReviewOrderUseCase', () => {
  let sut: CanReviewOrderUseCase;
  let mockPrisma: {
    order: { findUnique: jest.Mock };
    review: { findUnique: jest.Mock };
  };

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

  beforeEach(() => {
    mockPrisma = {
      order: {
        findUnique: jest.fn(),
      },
      review: {
        findUnique: jest.fn(),
      },
    };

    // @ts-expect-error - Mocking only the Prisma methods used in this use case for unit testing
    sut = new CanReviewOrderUseCase(mockPrisma);
  });

  describe('when order does not exist', () => {
    it('should return NOT_FOUND error', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'invalid-order',
        userId: 'user-1',
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('NOT_FOUND');
        expect(result.value.message).toContain('Order');
      }
    });
  });

  describe('when user is not part of the order', () => {
    it('should return canReview=false with reason', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'random-user',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(false);
        expect(result.value.reason).toBe('User is not part of this order');
      }
    });
  });

  describe('when order is not completed', () => {
    it('should return canReview=false with reason', async () => {
      const pendingOrder = { ...mockOrder, status: OrderStatus.PENDING };
      mockPrisma.order.findUnique.mockResolvedValue(pendingOrder);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'buyer-1',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(false);
        expect(result.value.reason).toBe('Order must be completed before reviewing');
      }
    });
  });

  describe('when buyer already reviewed seller', () => {
    it('should return canReview=false with reason', async () => {
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

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(false);
        expect(result.value.reason).toBe('You have already reviewed this order');
      }
    });
  });

  describe('when buyer can review seller', () => {
    it('should return canReview=true with BUYER_REVIEWING_SELLER type', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'buyer-1',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(true);
        expect(result.value.reviewType).toBe(ReviewType.BUYER_REVIEWING_SELLER);
        expect(result.value.reason).toBeUndefined();
      }
    });
  });

  describe('when seller can review buyer', () => {
    it('should return canReview=true with SELLER_REVIEWING_BUYER type', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.review.findUnique.mockResolvedValue(null);

      const result = await sut.execute({
        orderId: 'order-1',
        userId: 'seller-1',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(true);
        expect(result.value.reviewType).toBe(ReviewType.SELLER_REVIEWING_BUYER);
        expect(result.value.reason).toBeUndefined();
      }
    });
  });

  describe('when seller already reviewed buyer', () => {
    it('should return canReview=false with reason', async () => {
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

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.canReview).toBe(false);
        expect(result.value.reason).toBe('You have already reviewed this order');
      }
    });
  });
});
