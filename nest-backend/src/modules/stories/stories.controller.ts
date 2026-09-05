import {
  Controller,
  Param,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { saveUpload } from '@/shared/utils/file.utils';
import { StoriesService } from './stories.service';
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from '@/shared/decorators';
import { left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { validateImageFile } from '@/shared/utils/image-upload.utils';

@ApiTags('Stories')
@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @GetAuth({ summary: 'List active stories for explore/feed' })
  async getFeed() {
    return this.storiesService.getStories();
  }

  @GetAuth('user/:userId', {
    summary: 'List active stories for a specific user',
    params: [{ name: 'userId', description: 'User UUID' }],
  })
  async getUserStories(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.storiesService.getUserStories(userId);
  }

  @PostAuth({
    summary: 'Create a story',
    description: 'Uploads an image that will be available for 24h',
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async createStory(
    @CurrentUserId() userId: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) return left(new BadRequestError('Imagem é obrigatória'));
    const mimeError = validateImageFile(file);
    if (mimeError) return left(new BadRequestError(mimeError));

    return this.storiesService.createStory({
      userId,
      imageUrl: saveUpload(file, 'story'),
    });
  }

  @PatchAuth(':id/delete', {
    summary: 'Soft-delete a story',
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async deleteStory(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.storiesService.deleteStory({ storyId: id, userId });
  }

  @PostAuth(':id/view', {
    summary: 'View a story',
    description: 'Marks a story as viewed by the current user',
    params: [{ name: 'id', description: 'Story UUID' }],
  })
  async viewStory(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() viewerId: string) {
    return this.storiesService.viewStory({ storyId: id, viewerId: viewerId || '' });
  }
}
