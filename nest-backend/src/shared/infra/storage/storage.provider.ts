export abstract class StorageProvider {
  abstract upload(
    file: Express.Multer.File,
    context: string,
  ): Promise<{ url: string; key: string }>;

  abstract delete(key: string): Promise<void>;

  abstract getSignedUrl(
    key: string,
    expiresInSeconds?: number,
  ): Promise<string>;
}
