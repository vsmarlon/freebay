import {
  Controller,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BoundedMultipartInterceptor } from '@/shared/interceptors/bounded-multipart.interceptor';
import { CurrentUserId, PostAuth } from '@/shared/decorators';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import {
  MAX_MEDIA_SIZE,
  validateMediaFile,
} from '@/shared/utils/image-upload.utils';
import {
  isPrivateContext,
  UploadContext,
  saveUpload,
} from '@/shared/utils/file.utils';

const VALID_CONTEXTS = [
  'chat',
  'background',
  'post',
  'avatar',
  'product',
  'privatepost',
] as const satisfies readonly UploadContext[];

export function isValidContext(context: unknown): context is (typeof VALID_CONTEXTS)[number] {
  return typeof context === 'string' && (VALID_CONTEXTS as readonly string[]).includes(context);
}

@ApiTags('Upload')
@Controller('uploads')
export class UploadController {
  @PostAuth({ summary: 'Upload a file (image, audio, video)', responseStatus: 201, httpCode: HttpStatus.CREATED })
  @UseInterceptors(
    BoundedMultipartInterceptor('file', 1, MAX_MEDIA_SIZE + 512 * 1024, 4 * 1024, MAX_MEDIA_SIZE),
  )
  async upload(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Query('context') context: string,
    @CurrentUserId() userId: string,
  ): Promise<{ url: string; blurHash?: string }> {
    if (!file) {
      throw new BadRequestException(
        'Arquivo ausente ou formato não suportado (aceitos: JPEG, PNG, GIF, WebP, MP3, M4A, AAC, OGG, WAV, MP4, MOV, WebM)',
      );
    }
    if (!isValidContext(context)) {
      throw new BadRequestException(
        `Context inválido. Use: ${VALID_CONTEXTS.join(', ')}`,
      );
    }

    const validationError = validateMediaFile(file);
    if (validationError) {
      throw new BadRequestException(validationError);
    }

    const url = saveUpload(file, context, userId);
    const blurHash = file.mimetype.startsWith('image/') && !isPrivateContext(context)
      ? await generateImageBlurHash(file.buffer)
      : undefined;
    return { url, ...(blurHash ? { blurHash } : {}) };
  }
}
