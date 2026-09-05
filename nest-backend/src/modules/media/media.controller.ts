import {
  Controller,
  NotFoundException,
  Param,
  StreamableFile,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiTags } from '@nestjs/swagger';
import { createReadStream, existsSync } from 'fs';
import { join } from 'path';
import { GetAuth } from '@/shared/decorators';
import {
  PRIVATE_UPLOAD_ROOT,
  STORED_FILENAME,
  isPrivateContext,
  mimeForFilename,
} from '@/shared/utils/file.utils';

@ApiTags('Media')
@Controller('media')
export class MediaController {
  @GetAuth(':context/:filename', {
    summary: 'Serve a private upload to an authenticated user',
    description:
      'Chat attachments and conversation backgrounds are not publicly readable. ' +
      'Unlike /uploads, this route requires a valid access token.',
  })
  @Throttle({ short: { limit: 60, ttl: 1000 }, medium: { limit: 600, ttl: 60000 } })
  serve(
    @Param('context') context: string,
    @Param('filename') filename: string,
  ): StreamableFile {
    if (!isPrivateContext(context) || !STORED_FILENAME.test(filename)) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    const path = join(process.cwd(), PRIVATE_UPLOAD_ROOT, context, filename);
    if (!existsSync(path)) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    return new StreamableFile(createReadStream(path), {
      type: mimeForFilename(filename),
    });
  }
}
