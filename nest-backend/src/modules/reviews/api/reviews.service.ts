import { Injectable, Logger } from '@nestjs/common';
import { CreateReviewUseCase } from '../usecases/create-review/create-review.usecase';
import { GetUserReviewsUseCase } from '../usecases/get-user-reviews/get-user-reviews.usecase';
import { CanReviewOrderUseCase } from '../usecases/can-review-order/can-review-order.usecase';
import { ReviewRepository } from '../domain/repositories/review.repository';
import { CreateReviewInput } from './input/create-review.input';
import { AuthUser } from '@/shared/core/types';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { left, right, Either } from '@/shared/core/either';
import { ReviewType } from '@prisma/client';

@Injectable()
export class ReviewsService {
  private readonly logger = new Logger(ReviewsService.name);

  constructor(
    private readonly createReviewUseCase: CreateReviewUseCase,
    private readonly getUserReviewsUseCase: GetUserReviewsUseCase,
    private readonly canReviewOrderUseCase: CanReviewOrderUseCase,
    private readonly reviewRepository: ReviewRepository,
  ) {}

  async createReview(
    user: AuthUser,
    orderId: string,
    body: CreateReviewInput,
  ) {
    const imageUrls = (body.imageIds ?? [])
      .map((id) => this.tempImages.get(id))
      .filter((v): v is string => v !== undefined);

    body.imageIds?.forEach((id) => this.tempImages.delete(id));

    return this.createReviewUseCase.execute({
      reviewerId: user.userId,
      orderId,
      reviewedId: body.reviewedId,
      type: body.type,
      score: body.score,
      comment: body.comment,
      imageUrls: imageUrls.length > 0 ? imageUrls : undefined,
    });
  }

  async getUserReviews(userId: string, query: { offset?: number; limit?: number; type?: ReviewType }) {
    return this.getUserReviewsUseCase.execute({
      userId,
      ...query,
    });
  }

  async canReviewOrder(userId: string, orderId: string) {
    return this.canReviewOrderUseCase.execute({
      orderId,
      userId,
    });
  }

  private tempImages = new Map<string, string>();

  async uploadImage(orderId: string, file: Express.Multer.File | undefined): Promise<Either<AppError, { imageId: string; url: string }>> {
    if (!file) {
      return left(new BadRequestError('Arquivo de imagem é obrigatório'));
    }

    const validationError = validateImageFile(file);
    if (validationError) {
      return left(new BadRequestError(validationError));
    }

    const result = await this.reviewRepository.uploadImage({
      buffer: file.buffer,
      mimetype: file.mimetype,
    });

    if (result.isLeft()) {
      return left(result.value);
    }

    this.tempImages.set(result.value.imageId, result.value.url);

    return right({ imageId: result.value.imageId, url: result.value.url });
  }
}
