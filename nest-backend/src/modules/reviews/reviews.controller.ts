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
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { CreateReviewUseCase } from './usecases/create-review.usecase';
import { GetUserReviewsUseCase } from './usecases/get-user-reviews.usecase';
import { CanReviewOrderUseCase } from './usecases/can-review-order.usecase';
import { CreateReviewDTO, GetUserReviewsQueryDTO, GetUserReviewsOutput } from './dtos/review.dto';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Reviews')
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create review for an order',
    bodyType: CreateReviewDTO,
    responseStatus: 201,
    auth: true,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 400, description: 'Invalid input' }],
  })
  async create(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: CreateReviewDTO,
  ) {
    const result = await this.createReviewUseCase.execute({
      reviewerId: user.userId,
      orderId,
      reviewedId: body.reviewedId,
      type: body.type,
      score: body.score,
      comment: body.comment,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Get('users/:userId')
  async getUserReviews(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: GetUserReviewsQueryDTO,
  ) {
    const result = await this.getUserReviewsUseCase.execute({
      userId,
      ...query,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Get('orders/:orderId/can-review')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Check if user can review an order',
    auth: true,
    params: [{ name: 'orderId', description: 'Order UUID' }],
  })
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
