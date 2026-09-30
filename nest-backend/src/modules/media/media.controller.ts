import {
  Controller,
  NotFoundException,
  Param,
  Req,
  Res,
  StreamableFile,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiTags } from '@nestjs/swagger';
import { createReadStream, existsSync, statSync } from 'fs';
import { join } from 'path';
import { GetAuth, CurrentUserId } from '@/shared/decorators';
import {
  PRIVATE_UPLOAD_ROOT,
  PUBLIC_UPLOAD_ROOT,
  STORED_FILENAME,
  isPrivateContext,
  mimeForFilename,
} from '@/shared/utils/file.utils';
import { MediaAccessService } from './services/media-access.service';

export interface MediaRequest {
  headers?: {
    range?: string;
  };
}

export interface MediaResponse {
  setHeader?(name: string, value: string): void;
  status?(code: number): void;
}

@ApiTags('Media')
@Controller('media')
export class MediaController {
  constructor(private readonly mediaAccess: MediaAccessService) {}

  @GetAuth(':context/:filename', {
    summary: 'Serve a private upload to an authorized participant',
    description:
      'Chat attachments and conversation backgrounds are not publicly readable. ' +
      'The caller must be a participant of the conversation the file belongs to, ' +
      'and a burned view-once attachment is no longer served.',
  })
  @Throttle({ short: { limit: 60, ttl: 1000 }, medium: { limit: 600, ttl: 60000 } })
  async serve(
    @CurrentUserId() userId: string,
    @Param('context') context: string,
    @Param('filename') filename: string,
    @Req() req?: MediaRequest,
    @Res({ passthrough: true }) res?: MediaResponse,
  ): Promise<StreamableFile> {
    if (!isPrivateContext(context) || !STORED_FILENAME.test(filename)) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    const allowed = await this.mediaAccess.canRead(userId, context, filename);
    if (!allowed) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    const privatePath = join(process.cwd(), PRIVATE_UPLOAD_ROOT, context, filename);
    const path = context === 'story' && !existsSync(privatePath)
      ? join(process.cwd(), PUBLIC_UPLOAD_ROOT, context, filename)
      : privatePath;
    if (!existsSync(path)) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    const stat = statSync(path);
    const fileSize = stat.size;
    const mime = mimeForFilename(filename);
    const rangeHeader = req?.headers?.range;

    res?.setHeader?.('Accept-Ranges', 'bytes');
    res?.setHeader?.('Cache-Control', 'private, no-store');

    if (rangeHeader) {
      const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader);
      if (match) {
        const rawStart = match[1];
        const rawEnd = match[2];

        let start: number;
        let end: number;

        if (rawStart === '' && rawEnd !== '') {
          const suffix = parseInt(rawEnd, 10);
          start = Math.max(0, fileSize - suffix);
          end = fileSize - 1;
        } else {
          start = parseInt(rawStart, 10);
          end = rawEnd ? parseInt(rawEnd, 10) : fileSize - 1;
        }

        if (isNaN(start) || isNaN(end) || start > end || start >= fileSize) {
          res?.status?.(416);
          res?.setHeader?.('Content-Range', `bytes */${fileSize}`);
          return new StreamableFile(Buffer.from(''), { type: mime });
        }

        end = Math.min(end, fileSize - 1);
        const chunkSize = end - start + 1;

        res?.status?.(206);
        res?.setHeader?.('Content-Range', `bytes ${start}-${end}/${fileSize}`);
        res?.setHeader?.('Content-Length', String(chunkSize));

        return new StreamableFile(createReadStream(path, { start, end }), {
          type: mime,
          length: chunkSize,
        });
      }
    }

    res?.setHeader?.('Content-Length', String(fileSize));
    return new StreamableFile(createReadStream(path), {
      type: mime,
      length: fileSize,
    });
  }
}
