import {
  Controller,
  Query,
  Body,
  Param,
  UseInterceptors,
  UploadedFile,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ReviewsService } from './reviews.service';
import { CreateReviewInput } from './dtos/create-review.dto';
import {
  GetAuth,
  GetPublic,
  PostAuth,
  CurrentUser,
  CurrentUserId,
} from '@/shared/decorators';
import { AuthUser } from '@/shared/core/types';
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
  constructor(private readonly reviewsService: ReviewsService) {}

  @PostAuth('orders/:orderId', {
    summary: 'Create review for an order',
    bodyType: CreateReviewInput,
    responseStatus: 201,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [{ status: 400, description: 'Invalid input' }],
    httpCode: HttpStatus.CREATED,
  })
  async create(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: CreateReviewInput,
  ) {
    return this.reviewsService.createReview(user, orderId, body);
  }

  @PostAuth('orders/:orderId/images', {
    summary: 'Upload review image',
    params: [{ name: 'orderId', description: 'Order UUID' }],
    responseStatus: 201,
    errors: [{ status: 404, description: 'Image not found' }],
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadImage(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    return this.reviewsService.uploadImage(orderId, file);
  }

  @GetPublic('users/:userId', {
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
    return this.reviewsService.getUserReviews(userId, query);
  }

  @GetAuth('orders/:orderId/can-review', {
    summary: 'Check if user can review an order',
    params: [{ name: 'orderId', description: 'Order UUID' }],
  })
  async canReviewOrder(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.reviewsService.canReviewOrder(userId, orderId);
  }
}
