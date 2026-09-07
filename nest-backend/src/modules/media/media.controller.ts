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
import { GetAuth, CurrentUserId } from '@/shared/decorators';
import {
  PRIVATE_UPLOAD_ROOT,
  STORED_FILENAME,
  isPrivateContext,
  mimeForFilename,
} from '@/shared/utils/file.utils';
import { MediaAccessService } from './services/media-access.service';

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
  ): Promise<StreamableFile> {
    if (!isPrivateContext(context) || !STORED_FILENAME.test(filename)) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    const allowed = await this.mediaAccess.canRead(userId, context, filename);
    if (!allowed) {
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
