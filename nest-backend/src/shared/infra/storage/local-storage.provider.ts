import { Injectable } from '@nestjs/common';
import { StorageProvider } from './storage.provider';
import { join } from 'path';
import { mkdirSync, writeFileSync, unlinkSync, existsSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { MIMETYPE_EXTENSIONS } from '@/shared/utils/image-upload.utils';

@Injectable()
export class LocalStorageProvider implements StorageProvider {
  async upload(
    file: Express.Multer.File,
    context: string,
  ): Promise<{ url: string; key: string }> {
    const dir = join(process.cwd(), 'uploads', context);
    mkdirSync(dir, { recursive: true });

    const ext = MIMETYPE_EXTENSIONS[file.mimetype] || '.bin';
    const filename = `${uuidv4()}${ext}`;
    const filePath = join(dir, filename);

    if (file.buffer) {
      writeFileSync(filePath, file.buffer);
    }

    const key = `${context}/${filename}`;
    const url = `/uploads/${key}`;

    return { url, key };
  }

  async delete(key: string): Promise<void> {
    const filePath = join(process.cwd(), 'uploads', key);
    if (existsSync(filePath)) {
      unlinkSync(filePath);
    }
  }

  async getSignedUrl(key: string, _expiresInSeconds?: number): Promise<string> {
    return `/uploads/${key}`;
  }
}
