import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaReviewRepository } from '@/modules/reviews/data/repositories/review-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CreateReviewUsecaseInput, CreateReviewUsecaseOutput } from './create-review.dto';
import { OrderStatus, ReviewType } from '@prisma/client';

class InvalidOrderStateError extends AppError {
  constructor(message: string) {
    super('INVALID_ORDER_STATE', message, 400);
  }
}

class DuplicateReviewError extends AppError {
  constructor() {
    super('DUPLICATE_REVIEW', 'Você já avaliou este pedido', 400);
  }
}

class UnauthorizedReviewError extends AppError {
  constructor() {
    super('UNAUTHORIZED', 'Você não faz parte deste pedido', 403);
  }
}

@Injectable()
export class CreateReviewUseCase {
  constructor(
    private readonly reviewRepository: PrismaReviewRepository,
    private readonly prisma: PrismaService,
  ) {}

  async execute(
    input: CreateReviewUsecaseInput,
  ): Promise<Either<AppError, CreateReviewUsecaseOutput>> {
    if (input.score < 1 || input.score > 5) {
      return left(new BadRequestError('Score deve ser entre 1 e 5'));
    }

    if (input.comment && input.comment.length > 500) {
      return left(new BadRequestError('Comentário deve ter no máximo 500 caracteres'));
    }

    const order = await this.prisma.order.findUnique({
      where: { id: input.orderId },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.status !== OrderStatus.COMPLETED) {
      return left(
        new InvalidOrderStateError('Pedido deve estar completo para ser avaliado'),
      );
    }

    const isReviewerPartOfOrder =
      input.reviewerId === order.buyerId || input.reviewerId === order.sellerId;

    if (!isReviewerPartOfOrder) {
      return left(new UnauthorizedReviewError());
    }

    if (input.type === ReviewType.BUYER_REVIEWING_SELLER) {
      if (input.reviewerId !== order.buyerId) {
        return left(new BadRequestError('Apenas o comprador pode avaliar o vendedor'));
      }
      if (input.reviewedId !== order.sellerId) {
        return left(new BadRequestError('reviewedId deve ser o vendedor'));
      }
    }

    if (input.type === ReviewType.SELLER_REVIEWING_BUYER) {
      if (input.reviewerId !== order.sellerId) {
        return left(new BadRequestError('Apenas o vendedor pode avaliar o comprador'));
      }
      if (input.reviewedId !== order.buyerId) {
        return left(new BadRequestError('reviewedId deve ser o comprador'));
      }
    }

    const existingReviewResult = await this.reviewRepository.findExistingReview(
      input.reviewerId,
      input.orderId,
      input.type,
    );

    if (isLeft(existingReviewResult)) {
      return left(existingReviewResult.value);
    }

    if (existingReviewResult.value) {
      return left(new DuplicateReviewError());
    }

    const review = await this.prisma.$transaction(async (tx) => {
      const created = await tx.review.create({
        data: {
          reviewer: { connect: { id: input.reviewerId } },
          reviewed: { connect: { id: input.reviewedId } },
          order: { connect: { id: input.orderId } },
          type: input.type,
          score: input.score,
          comment: input.comment,
          images:
            input.imageUrls && input.imageUrls.length > 0
              ? {
                  create: input.imageUrls.map((url, index) => ({
                    url,
                    order: index,
                  })),
                }
              : undefined,
        },
        include: {
          reviewer: {
            select: { id: true, displayName: true, avatarUrl: true, isVerified: true },
          },
          images: { orderBy: { order: 'asc' } },
        },
      });

      return created;
    });

    const updateResult = await this.reviewRepository.updateUserReputation(input.reviewedId);

    if (isLeft(updateResult)) {
      return left(updateResult.value);
    }

    return right({
      id: review.id,
      reviewerId: review.reviewerId,
      reviewedId: review.reviewedId,
      orderId: review.orderId,
      type: review.type,
      score: review.score,
      comment: review.comment,
      createdAt: review.createdAt,
      images: review.images.map((img) => ({
        id: img.id,
        url: img.url,
        order: img.order,
      })),
      reviewer: review.reviewer,
    });
  }
}
