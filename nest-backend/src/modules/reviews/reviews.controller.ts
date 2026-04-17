import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { CreateReviewUseCase } from './usecases/create-review.usecase';
import { GetUserReviewsUseCase } from './usecases/get-user-reviews.usecase';
import { CanReviewOrderUseCase } from './usecases/can-review-order.usecase';
import { createReviewSchema, getUserReviewsQuerySchema } from './dtos/review.dto';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ReviewType } from '@prisma/client';

@Controller('reviews')
export class ReviewsController {
  constructor(
    private readonly createReviewUseCase: CreateReviewUseCase,
    private readonly getUserReviewsUseCase: GetUserReviewsUseCase,
    private readonly canReviewOrderUseCase: CanReviewOrderUseCase,
  ) {}

  @Post('orders/:orderId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: { reviewedId: string; type: ReviewType; score: number; comment?: string },
  ) {
    const input = createReviewSchema.safeParse({
      reviewerId: user.userId,
      orderId,
      ...body,
    });

    if (!input.success) {
      return left(new AppError('BAD_REQUEST', input.error.errors[0].message, 400));
    }

    const result = await this.createReviewUseCase.execute(input.data);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Get('users/:userId')
  async getUserReviews(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: { page?: string; limit?: string; type?: ReviewType },
  ) {
    const parsedQuery = getUserReviewsQuerySchema.safeParse(query);

    if (!parsedQuery.success) {
      return left(new AppError('BAD_REQUEST', parsedQuery.error.errors[0].message, 400));
    }

    const result = await this.getUserReviewsUseCase.execute({
      userId,
      ...parsedQuery.data,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Get('orders/:orderId/can-review')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async canReviewOrder(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
  ) {
    const result = await this.canReviewOrderUseCase.execute({
      orderId,
      userId: user.userId,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }
}
