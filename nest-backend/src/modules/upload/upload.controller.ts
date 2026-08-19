import {
  Controller,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { join } from 'path';
import { mkdirSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { ApiTags } from '@nestjs/swagger';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import {
  MAX_MEDIA_SIZE,
  MIMETYPE_EXTENSIONS,
  validateMediaFile,
} from '@/shared/utils/image-upload.utils';

const VALID_CONTEXTS = ['chat', 'background', 'post', 'avatar'] as const;

export function isValidContext(context: unknown): context is (typeof VALID_CONTEXTS)[number] {
  return typeof context === 'string' && (VALID_CONTEXTS as readonly string[]).includes(context);
}

@ApiTags('Upload')
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadController {
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiDoc({ summary: 'Upload a file to disk (image, audio, video)', auth: true, responseStatus: 201 })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, _file, cb) => {
          const context = req.query.context;
          if (!isValidContext(context)) {
            cb(
              new BadRequestException(
                `Context inválido. Use: ${VALID_CONTEXTS.join(', ')}`,
              ),
              '',
            );
            return;
          }
          const dir = join(process.cwd(), 'uploads', context);
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) => {
          const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
          cb(null, `${uuidv4()}${ext}`);
        },
      }),
      limits: { fileSize: MAX_MEDIA_SIZE },
      fileFilter: (_req, file, cb) => {
        cb(null, file.mimetype in MIMETYPE_EXTENSIONS);
      },
    }),
  )
  upload(
    @UploadedFile() file: Express.Multer.File,
    @Query('context') context: string,
  ): { url: string } {
    if (!file) {
      throw new BadRequestException(
        'Arquivo ausente ou formato não suportado (aceitos: JPEG, PNG, GIF, WebP, MP3, M4A, AAC, OGG, WAV, MP4)',
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

    return { url: `/uploads/${context}/${file.filename}` };
  }
}
