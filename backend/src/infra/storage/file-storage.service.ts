import fs from 'fs';
import path from 'path';

export class FileStorageService {
  private uploadsDir: string;

  constructor(uploadsDir?: string) {
    this.uploadsDir = uploadsDir ?? path.join(process.cwd(), 'uploads');
  }

  async saveBase64Image(base64Data: string, prefix: string): Promise<string> {
    if (!fs.existsSync(this.uploadsDir)) {
      fs.mkdirSync(this.uploadsDir, { recursive: true });
    }

    // Remove data URL prefix if present
    const cleanBase64 = base64Data.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(cleanBase64, 'base64');

    const filename = `${prefix}_${Date.now()}.jpg`;
    const filepath = path.join(this.uploadsDir, filename);

    fs.writeFileSync(filepath, buffer);

    return `/uploads/${filename}`;
  }
}
