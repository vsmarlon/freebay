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
  UploadedFile,
  UseInterceptors,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ReviewsService } from './reviews.service';
import { CreateReviewInput } from './input/create-review.input';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { IsOptional, IsInt, Min, Max, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { ReviewType } from '@prisma/client';

class GetUserReviewsQueryDTO {
  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({ enum: ReviewType })
  @IsOptional()
  @IsEnum(ReviewType)
  type?: ReviewType;
}

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
  private readonly logger = new Logger(ReviewsController.name);

  constructor(private readonly reviewsService: ReviewsService) {}

  @Post('orders/:orderId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create review for an order',
    bodyType: CreateReviewInput,
    responseStatus: 201,
    auth: true,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 400, description: 'Invalid input' }],
  })
  async create(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: CreateReviewInput,
  ) {
    const result = await this.reviewsService.createReview(user, orderId, body);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Post('orders/:orderId/images')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Upload review image',
    auth: true,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    responseStatus: 201,
  })
  async uploadImage(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    const result = await this.reviewsService.uploadImage(orderId, file);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Get('users/:userId')
  @ApiDoc({
    summary: 'Get user reviews',
    params: [{ name: 'userId', description: 'User UUID' }],
    queries: [
      { name: 'offset', required: false, description: 'Pagination offset' },
      { name: 'limit', required: false, description: 'Results per page' },
      { name: 'type', required: false, description: 'Review type filter' },
    ],
  })
  async getUserReviews(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: GetUserReviewsQueryDTO,
  ) {
    const result = await this.reviewsService.getUserReviews(userId, query);

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
    const result = await this.reviewsService.canReviewOrder(user.userId, orderId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }
}
