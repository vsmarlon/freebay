import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { ReviewsService } from './reviews.service';
import { CreateReviewInput } from './dtos/create-review.dto';
import { CanReviewOrderUseCase } from './usecases/can-review-order/can-review-order.usecase';
import { CreateReviewUseCase } from './usecases/create-review/create-review.usecase';
import { GetUserReviewsUseCase } from './usecases/get-user-reviews/get-user-reviews.usecase';
import { ReviewDatabaseRepository } from './data/repositories/review-database.repository';

describe('ReviewsService.createReview pending-image ownership', () => {
  const createReviewUseCase = { execute: jest.fn() };
  const getUserReviewsUseCase = { execute: jest.fn() };
  const canReviewOrderUseCase = { execute: jest.fn() };
  const reviewRepository = { uploadImage: jest.fn() };

  const pngFile = {
    mimetype: 'image/png',
    buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    size: 8,
  } as Express.Multer.File;

  const auth = (userId: string): AuthUser => ({ userId, role: UserRole.USER });

  const reviewBody = (imageIds: string[]): CreateReviewInput => ({
    reviewedId: 'seller-1',
    type: 'BUYER_REVIEWING_SELLER',
    score: 5,
    comment: 'ok',
    imageIds,
  });

  let sut: ReviewsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    createReviewUseCase.execute.mockResolvedValue(right({ review: {} }));
    canReviewOrderUseCase.execute.mockResolvedValue(right({ canReview: true }));
    const module = await Test.createTestingModule({
      providers: [
        ReviewsService,
        { provide: CreateReviewUseCase, useValue: createReviewUseCase },
        { provide: GetUserReviewsUseCase, useValue: getUserReviewsUseCase },
        { provide: CanReviewOrderUseCase, useValue: canReviewOrderUseCase },
        { provide: ReviewDatabaseRepository, useValue: reviewRepository },
      ],
    }).compile();
    sut = module.get(ReviewsService);
  });

  it('does not let another user claim or destroy a pending review image', async () => {
    reviewRepository.uploadImage.mockResolvedValue(
      right({ imageId: 'image-1', url: '/uploads/review/image-1.png' }),
    );
    const uploaded = await sut.uploadImage('order-1', pngFile, 'buyer-1');
    expect(uploaded.isRight()).toBe(true);

    await sut.createReview(auth('stranger-1'), 'order-2', reviewBody(['image-1']));
    expect(createReviewUseCase.execute).toHaveBeenCalledWith(expect.objectContaining({
      reviewerId: 'stranger-1',
      imageUrls: undefined,
    }));

    await sut.createReview(auth('buyer-1'), 'order-1', reviewBody(['image-1']));
    expect(createReviewUseCase.execute).toHaveBeenLastCalledWith(expect.objectContaining({
      reviewerId: 'buyer-1',
      imageUrls: ['/uploads/review/image-1.png'],
    }));

    await sut.createReview(auth('buyer-1'), 'order-1', reviewBody(['image-1']));
    expect(createReviewUseCase.execute).toHaveBeenLastCalledWith(expect.objectContaining({
      reviewerId: 'buyer-1',
      imageUrls: undefined,
    }));
  });

  it('does not resolve a pending image on a different order than it was uploaded for', async () => {
    reviewRepository.uploadImage.mockResolvedValue(
      right({ imageId: 'image-2', url: '/uploads/review/image-2.png' }),
    );
    const uploaded = await sut.uploadImage('order-1', pngFile, 'buyer-1');
    expect(uploaded.isRight()).toBe(true);

    await sut.createReview(auth('buyer-1'), 'order-2', reviewBody(['image-2']));
    expect(createReviewUseCase.execute).toHaveBeenCalledWith(expect.objectContaining({
      orderId: 'order-2',
      imageUrls: undefined,
    }));

    await sut.createReview(auth('buyer-1'), 'order-1', reviewBody(['image-2']));
    expect(createReviewUseCase.execute).toHaveBeenLastCalledWith(expect.objectContaining({
      orderId: 'order-1',
      imageUrls: ['/uploads/review/image-2.png'],
    }));
  });

  it('resolves duplicate image ids once instead of duplicating image rows', async () => {
    reviewRepository.uploadImage.mockResolvedValue(
      right({ imageId: 'image-3', url: '/uploads/review/image-3.png' }),
    );
    await sut.uploadImage('order-1', pngFile, 'buyer-1');

    await sut.createReview(auth('buyer-1'), 'order-1', reviewBody(['image-3', 'image-3']));

    expect(createReviewUseCase.execute).toHaveBeenCalledWith(expect.objectContaining({
      imageUrls: ['/uploads/review/image-3.png'],
    }));
  });
});

describe('ReviewsService uploadImage', () => {
  const createReviewUseCase = { execute: jest.fn() };
  const getUserReviewsUseCase = { execute: jest.fn() };
  const canReviewOrderUseCase = { execute: jest.fn() };
  const reviewRepository = { uploadImage: jest.fn() };

  const pngFile = {
    mimetype: 'image/png',
    buffer: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    size: 8,
  } as Express.Multer.File;

  let sut: ReviewsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        ReviewsService,
        { provide: CreateReviewUseCase, useValue: createReviewUseCase },
        { provide: GetUserReviewsUseCase, useValue: getUserReviewsUseCase },
        { provide: CanReviewOrderUseCase, useValue: canReviewOrderUseCase },
        { provide: ReviewDatabaseRepository, useValue: reviewRepository },
      ],
    }).compile();
    sut = module.get(ReviewsService);
  });

  it('stays authorized by the order eligibility check, not by orderId alone', async () => {
    canReviewOrderUseCase.execute.mockResolvedValue(right({ canReview: true }));
    reviewRepository.uploadImage.mockResolvedValue(
      right({ imageId: 'image-1', url: '/uploads/review/image-1.png' }),
    );

    const result = await sut.uploadImage('order-1', pngFile, 'buyer-1');

    expect(canReviewOrderUseCase.execute).toHaveBeenCalledWith({
      orderId: 'order-1',
      userId: 'buyer-1',
    });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toEqual({
        imageId: 'image-1',
        url: '/uploads/review/image-1.png',
      });
    }
  });

  it.each([
    'User is not part of this order',
    'Order must be completed before reviewing',
  ])('rejects %s without storing the file', async (reason) => {
    canReviewOrderUseCase.execute.mockResolvedValue(right({ canReview: false, reason }));

    const result = await sut.uploadImage('order-1', pngFile, 'stranger-1');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(ForbiddenError);
      expect(result.value.statusCode).toBe(403);
    }
    expect(reviewRepository.uploadImage).not.toHaveBeenCalled();
  });

  it('propagates a missing order as not found', async () => {
    canReviewOrderUseCase.execute.mockResolvedValue(left(new NotFoundError('Order')));

    const result = await sut.uploadImage('missing-order', pngFile, 'buyer-1');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
    expect(reviewRepository.uploadImage).not.toHaveBeenCalled();
  });
});
