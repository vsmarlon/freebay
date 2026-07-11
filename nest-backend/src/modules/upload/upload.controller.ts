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
import { extname, join } from 'path';
import { mkdirSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { ApiTags } from '@nestjs/swagger';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

const VALID_CONTEXTS = ['chat', 'background', 'post', 'avatar'] as const;
const VALID_MIMETYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

@ApiTags('Upload')
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadController {
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiDoc({ summary: 'Upload a file to disk', auth: true, responseStatus: 201 })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, _file, cb) => {
          const context = (req.query.context as string) || 'misc';
          const dir = join(process.cwd(), 'uploads', context);
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) => {
          const ext = extname(file.originalname).toLowerCase() || '.jpg';
          cb(null, `${uuidv4()}${ext}`);
        },
      }),
      limits: { fileSize: MAX_SIZE },
      fileFilter: (_req, file, cb) => {
        cb(null, VALID_MIMETYPES.includes(file.mimetype));
      },
    }),
  )
  upload(
    @UploadedFile() file: Express.Multer.File,
    @Query('context') context: string,
  ): { url: string } {
    if (!file) {
      throw new BadRequestException(
        'Arquivo ausente ou tipo não permitido (aceitos: jpeg, png, gif, webp)',
      );
    }
    if (!VALID_CONTEXTS.includes(context as any)) {
      throw new BadRequestException(
        `Context inválido. Use: ${VALID_CONTEXTS.join(', ')}`,
      );
    }
    return { url: `/uploads/${context}/${file.filename}` };
  }
}
