import {
  Controller,
  Get,
  Post,
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
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
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

  @Post('orders/:orderId')
  @Authenticated({
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

  @Post('orders/:orderId/images')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @Authenticated({
    summary: 'Upload review image',
    params: [{ name: 'orderId', description: 'Order UUID' }],
    responseStatus: 201,
    errors: [{ status: 404, description: 'Image not found' }],
    httpCode: HttpStatus.CREATED,
  })
  async uploadImage(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() _user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    return this.reviewsService.uploadImage(orderId, file);
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
    return this.reviewsService.getUserReviews(userId, query);
  }

  @Get('orders/:orderId/can-review')
  @Authenticated({
    summary: 'Check if user can review an order',
    params: [{ name: 'orderId', description: 'Order UUID' }],
  })
  async canReviewOrder(
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.reviewsService.canReviewOrder(user.userId, orderId);
  }
}
