import { GetUserReviewsUseCase } from './get-user-reviews.usecase';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory, OrderFactory } from '../../../../../test/factories';
import { createMockConfigService } from '../../../../../test/utils/test-helpers';
import { isLeft, isRight } from '@/shared/core/either';
import { ReviewType } from '@prisma/client';
import { CreateReviewUseCase } from '../create-review/create-review.usecase';

describe('GetUserReviewsUseCase Integration', () => {
  let sut: GetUserReviewsUseCase;
  let createReviewUseCase: CreateReviewUseCase;
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
    createReviewUseCase = new CreateReviewUseCase(reviewRepository, prismaService);
    sut = new GetUserReviewsUseCase(reviewRepository, prismaService);
  });

  describe('Business Rules', () => {
    it('should return empty list when user has no reviews', async () => {
      const user = await userFactory.create();

      const result = await sut.execute({ userId: user.id });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.reviews).toHaveLength(0);
        expect(result.value.total).toBe(0);
      }
    });

    it('should return reviews received by user', async () => {
      const seller = await userFactory.create();
      const buyer = await userFactory.create();
      const product = await productFactory.create(seller.id);
      const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

      await createReviewUseCase.execute({
        reviewerId: buyer.id,
        orderId: order.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
        comment: 'Ótimo vendedor!',
      });

      const result = await sut.execute({ userId: seller.id });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.reviews).toHaveLength(1);
        expect(result.value.total).toBe(1);
        expect(result.value.reviews[0].score).toBe(5);
        expect(result.value.reviews[0].reviewer.id).toBe(buyer.id);
      }
    });

    it('should filter reviews by type', async () => {
      const seller = await userFactory.create();
      const buyer1 = await userFactory.create();
      await userFactory.create();

      const product1 = await productFactory.create(seller.id);
      const product2 = await productFactory.create(buyer1.id);

      const order1 = await orderFactory.createCompleted(buyer1.id, seller.id, product1.id);
      const order2 = await orderFactory.createCompleted(seller.id, buyer1.id, product2.id);

      await createReviewUseCase.execute({
        reviewerId: buyer1.id,
        orderId: order1.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      await createReviewUseCase.execute({
        reviewerId: buyer1.id,
        orderId: order2.id,
        reviewedId: seller.id,
        type: ReviewType.SELLER_REVIEWING_BUYER,
        score: 4,
      });

      const result = await sut.execute({
        userId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.reviews).toHaveLength(1);
        expect(result.value.reviews[0].type).toBe(ReviewType.BUYER_REVIEWING_SELLER);
      }
    });

    it('should paginate reviews', async () => {
      const seller = await userFactory.create();

      for (let i = 0; i < 5; i++) {
        const buyer = await userFactory.create();
        const product = await productFactory.create(seller.id);
        const order = await orderFactory.createCompleted(buyer.id, seller.id, product.id);

        await createReviewUseCase.execute({
          reviewerId: buyer.id,
          orderId: order.id,
          reviewedId: seller.id,
          type: ReviewType.BUYER_REVIEWING_SELLER,
          score: 5 - i,
        });
      }

      const result1 = await sut.execute({ userId: seller.id, offset: 0, limit: 2 });
      const result2 = await sut.execute({ userId: seller.id, offset: 2, limit: 2 });

      expect(isRight(result1)).toBe(true);
      expect(isRight(result2)).toBe(true);

      if (isRight(result1) && isRight(result2)) {
        expect(result1.value.reviews).toHaveLength(2);
        expect(result1.value.total).toBe(5);
        expect(result1.value.offset).toBe(0);

        expect(result2.value.reviews).toHaveLength(2);
        expect(result2.value.offset).toBe(2);
      }
    });

    it('should return reviews sorted by most recent first', async () => {
      const seller = await userFactory.create();
      const buyer1 = await userFactory.create();
      const buyer2 = await userFactory.create();

      const product1 = await productFactory.create(seller.id);
      const product2 = await productFactory.create(seller.id);

      const order1 = await orderFactory.createCompleted(buyer1.id, seller.id, product1.id);
      const order2 = await orderFactory.createCompleted(buyer2.id, seller.id, product2.id);

      await createReviewUseCase.execute({
        reviewerId: buyer1.id,
        orderId: order1.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 3,
      });

      await new Promise((r) => setTimeout(r, 50));

      await createReviewUseCase.execute({
        reviewerId: buyer2.id,
        orderId: order2.id,
        reviewedId: seller.id,
        type: ReviewType.BUYER_REVIEWING_SELLER,
        score: 5,
      });

      const result = await sut.execute({ userId: seller.id });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        expect(result.value.reviews).toHaveLength(2);
        expect(result.value.reviews[0].score).toBe(5);
        expect(result.value.reviews[1].score).toBe(3);
      }
    });

    it('should return error if user does not exist', async () => {
      const result = await sut.execute({ userId: 'non-existent-id' });

      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.value.code).toBe('NOT_FOUND');
      }
    });
  });
});
