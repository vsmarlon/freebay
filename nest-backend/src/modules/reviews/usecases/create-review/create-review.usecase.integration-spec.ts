import { CreateReviewUseCase } from './create-review.usecase';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory, OrderFactory } from '../../../../../test/factories';
import { createMockConfigService } from '../../../../../test/utils/test-helpers';
import { isLeft, isRight } from '@/shared/core/either';
import { ReviewType } from '@prisma/client';

describe('CreateReviewUseCase Integration', () => {
  let sut: CreateReviewUseCase;
  let reviewRepository: PrismaReviewRepository;
  let prismaService: PrismaService;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;
  let orderFactory: OrderFactory;

  beforeEach(() => {
    const mockConfig = createMockConfigService();
    prismaService = new PrismaService(mockConfig);
    reviewRepository = new PrismaReviewRepository(prismaService);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    orderFactory = new OrderFactory(prisma);
    sut = new CreateReviewUseCase(reviewRepository, prismaService);
  });

  describe('Business Rules', () => {
    it('should create buyer review for seller on completed order', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
        comment: 'Excelente vendedor!',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const review = result.value;
        expect(review.reviewerId).toBe(buyer.id);
        expect(review.reviewedId).toBe(seller.id);
        expect(review.orderId).toBe(order.id);
        expect(review.type).toBe(ReviewType.BUYER_REVIEWING_SELLER);
        expect(review.score).toBe(5);
        expect(review.comment).toBe('Excelente vendedor!');
      }
    });

    it('should create seller review for buyer on completed order', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: seller.id,
        orderId: order.id,
        reviewedId: buyer.id,
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 4,
        comment: 'Comprador pontual',
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const review = result.value;
        expect(review.type).toBe(ReviewType.SELLER_REVIEWING_BUYER);
        expect(review.score).toBe(4);
      }
    });

    it('should update user reputation after creating review', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isRight(result)).toBe(true);

      const updatedSeller = await prisma.user.findUnique({
        where: { id: seller.id },
      });

      expect(updatedSeller?.reputationScore).toBe(5);
      expect(updatedSeller?.totalReviews).toBe(1);
    });

    it('should calculate correct average reputation with multiple reviews', async () => {
      const seller = await userFactory.create();
      const buyer1 = await userFactory.create();
      const buyer2 = await userFactory.create();
      const buyer3 = await userFactory.create();

      const product1 = await productFactory.create(seller.id);
      const product2 = await productFactory.create(seller.id);
      const product3 = await productFactory.create(seller.id);

      const order1 = await orderFactory.createCompleted(buyer1.id, seller.id, product1.id);
      const order2 = await orderFactory.createCompleted(buyer2.id, seller.id, product2.id);
      const order3 = await orderFactory.createCompleted(buyer3.id, seller.id, product3.id);

      await sut.execute({
        reviewerId: buyer1.id,
        orderId: order1.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      await sut.execute({
        reviewerId: buyer2.id,
        orderId: order2.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 4,
      });

      await sut.execute({
        reviewerId: buyer3.id,
        orderId: order3.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 3,
      });

      const updatedSeller = await prisma.user.findUnique({
        where: { id: seller.id },
      });

      expect(updatedSeller?.reputationScore).toBe(4);
      expect(updatedSeller?.totalReviews).toBe(3);
    });

    it('should reject review if order does not exist', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: 'non-existent-order-id',
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('NOT_FOUND');
        expect(result.value.message).toContain('Order');
      }
    });

    it('should reject review if order is not completed', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.create(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('INVALID_ORDER_STATE');
        expect(result.value.message).toContain('completo');
      }
    });

    it('should reject duplicate review for same order and type', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 4,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('DUPLICATE_REVIEW');
        expect(result.value.message).toContain('já avaliou');
      }
    });

    it('should allow both buyer and seller to review same order', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result1 = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      const result2 = await sut.execute({
        reviewerId: seller.id,
        orderId: order.id,
        reviewedId: buyer.id,
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 4,
      });

      expect(isRight(result1)).toBe(true);
      expect(isRight(result2)).toBe(true);

      const reviews = await prisma.review.findMany({
        where: { orderId: order.id },
      });

      expect(reviews).toHaveLength(2);
    });

    it('should reject review with invalid score', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 0,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
      }
    });

    it('should allow review without comment', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const review = result.value;
        expect(review.comment).toBeNull();
      }
    });

    it('should reject review if reviewer is not part of order', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const stranger = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: stranger.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('UNAUTHORIZED');
        expect(result.value.message).toContain('não faz parte');
      }
    });

    it('should reject review with comment exceeding 500 characters', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);
      const longComment = 'a'.repeat(501);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
        comment: longComment,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
        expect(result.value.message).toContain('500 caracteres');
      }
    });

    it('should reject if buyer tries to review with wrong reviewedId', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const otherUser = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: otherUser.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
        expect(result.value.message).toContain('vendedor');
      }
    });

    it('should reject if seller tries to use BUYER_REVIEWING_SELLER type', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: seller.id,
        orderId: order.id,
        reviewedId: buyer.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
        expect(result.value.message).toContain('comprador pode avaliar o vendedor');
      }
    });

    it('should reject if seller tries to review with wrong reviewedId', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const otherUser = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: seller.id,
        orderId: order.id,
        reviewedId: otherUser.id,
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
        expect(result.value.message).toContain('comprador');
      }
    });

    it('should reject if buyer tries to use SELLER_REVIEWING_BUYER type', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      const result = await sut.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 5,
      });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('BAD_REQUEST');
        expect(result.value.message).toContain('vendedor pode avaliar o comprador');
      }
    });
  });
});
