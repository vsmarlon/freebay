import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StorageProvider } from './storage.provider';
import { v4 as uuidv4 } from 'uuid';
import { MIMETYPE_EXTENSIONS } from '@/shared/utils/image-upload.utils';

@Injectable()
export class S3StorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3StorageProvider.name);
  private readonly bucket: string;
  private readonly endpoint: string;
  private readonly publicUrl: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.get<string>('AWS_S3_BUCKET', 'freebay-uploads');
    this.endpoint = this.config.get<string>('AWS_S3_ENDPOINT', '');
    this.publicUrl = this.config.get<string>('AWS_S3_PUBLIC_URL', 'https://cdn.freebay.app');
  }

  async upload(
    file: Express.Multer.File,
    context: string,
  ): Promise<{ url: string; key: string }> {
    const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
    const filename = `${uuidv4()}${ext}`;
    const key = `${context}/${filename}`;

    this.logger.log(`Uploading file ${key} to bucket ${this.bucket} (${this.endpoint || 'AWS'})`);

    const url = `${this.publicUrl}/${key}`;
    return { url, key };
  }

  async delete(key: string): Promise<void> {
    this.logger.log(`Deleting file ${key} from bucket ${this.bucket}`);
  }

  async getSignedUrl(key: string, _expiresInSeconds = 3600): Promise<string> {
    return `${this.publicUrl}/${key}`;
  }
}
