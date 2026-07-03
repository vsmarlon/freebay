import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { StoriesService } from './stories.service';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { validateImageFile } from '@/shared/utils/image-upload.utils';

@ApiTags('Stories')
@Controller('stories')
export class StoriesController {
  constructor(
    private readonly storiesService: StoriesService,
  ) {}

  @Get()
  @ApiDoc({
    summary: 'Get stories feed',
    description: 'Returns active stories from followed users',
  })
  async getStories(@CurrentUser() user: AuthUser) {
    const result = await this.storiesService.getStories(user?.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { stories: result.value.stories, userHasStory: result.value.userHasStory };
  }

  @Get('user/:userId')
  @ApiDoc({
    summary: 'Get user stories',
    params: [{ name: 'userId', description: 'User UUID' }],
  })
  async getUserStories(@Param('userId') userId: string) {
    const result = await this.storiesService.getUserStories(userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { stories: result.value };
  }

  @Post()
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
    summary: 'Create a story',
    description: 'Uploads an image that will be available for 24h',
    auth: true,
    responseStatus: 201,
  })
  async createStory(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      return left(new AppError('BAD_REQUEST', 'Imagem é obrigatória'));
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      return left(new AppError('BAD_REQUEST', mimeError));
    }

    const userId = user.userId;
    const result = await this.storiesService.createStory({
      userId,
      imageBase64: this.storiesService.toDataUri(file),
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Delete a story',
    auth: true,
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async deleteStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.storiesService.deleteStory({ storyId: id, userId: user.userId });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post(':id/view')
  @ApiDoc({
    summary: 'View a story',
    description: 'Marks a story as viewed by the current user',
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async viewStory(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.storiesService.viewStory({ storyId: id, viewerId: user?.userId || '' });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
