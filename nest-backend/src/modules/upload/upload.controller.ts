import {
  Controller,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth } from '@/shared/decorators';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import {
  MAX_MEDIA_SIZE,
  MIMETYPE_EXTENSIONS,
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
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_MEDIA_SIZE },
      fileFilter: (_req, file, cb) => {
        cb(null, file.mimetype in MIMETYPE_EXTENSIONS);
      },
    }),
  )
  async upload(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Query('context') context: string,
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

    const url = saveUpload(file, context);
    const blurHash = file.mimetype.startsWith('image/') && !isPrivateContext(context)
      ? await generateImageBlurHash(file.buffer)
      : undefined;
    return { url, ...(blurHash ? { blurHash } : {}) };
  }
}
