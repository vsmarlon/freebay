import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaReviewRepository } from '../repositories/review.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CreateReviewDto } from '../dtos/review.dto';
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
    private reviewRepository: PrismaReviewRepository,
    private prisma: PrismaService,
  ) {}

  async execute(input: CreateReviewDto): Promise<Either<AppError, any>> {
    // Validate score range
    if (input.score < 1 || input.score > 5) {
      return left(new BadRequestError('Score deve ser entre 1 e 5'));
    }

    // Validate comment length
    if (input.comment && input.comment.length > 500) {
      return left(new BadRequestError('Comentário deve ter no máximo 500 caracteres'));
    }

    // Check if order exists
    const order = await this.prisma.order.findUnique({
      where: { id: input.orderId },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    // Check if order is completed
    if (order.status !== OrderStatus.COMPLETED) {
      return left(
        new InvalidOrderStateError('Pedido deve estar completo para ser avaliado'),
      );
    }

    // Check if reviewer is part of the order
    const isReviewerPartOfOrder =
      input.reviewerId === order.buyerId || input.reviewerId === order.sellerId;

    if (!isReviewerPartOfOrder) {
      return left(new UnauthorizedReviewError());
    }

    // Validate review type matches order participants
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

    // Check if review already exists
    const existingReview = await this.reviewRepository.findExistingReview(
      input.reviewerId,
      input.orderId,
      input.type,
    );

    if (existingReview) {
      return left(new DuplicateReviewError());
    }

    // Create review
    const review = await this.reviewRepository.create({
      reviewer: { connect: { id: input.reviewerId } },
      reviewed: { connect: { id: input.reviewedId } },
      order: { connect: { id: input.orderId } },
      type: input.type,
      score: input.score,
      comment: input.comment,
    });

    // Update user reputation
    await this.reviewRepository.updateUserReputation(input.reviewedId);

    return right(review);
  }
}
