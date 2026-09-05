import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate, ExecutionContext, NotFoundException, StreamableFile } from '@nestjs/common';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { join } from 'path';
import { MediaController } from './media.controller';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PRIVATE_UPLOAD_ROOT } from '@/shared/utils/file.utils';

class MockJwtGuard implements CanActivate {
  canActivate(_context: ExecutionContext): boolean {
    return true;
  }
}

const EXISTING = '11111111-2222-4333-8444-555555555555.jpg';

describe('MediaController', () => {
  let sut: MediaController;
  const dir = join(process.cwd(), PRIVATE_UPLOAD_ROOT, 'chat');

  beforeAll(() => {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, EXISTING), 'bytes');
  });

  afterAll(() => {
    rmSync(join(dir, EXISTING), { force: true });
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MediaController],
    })
      .overrideGuard(JwtAuthGuard)
      .useClass(MockJwtGuard)
      .compile();
    sut = module.get<MediaController>(MediaController);
  });

  it('streams an existing private file', () => {
    const result = sut.serve('chat', EXISTING);
    expect(result).toBeInstanceOf(StreamableFile);
    expect(result.options.type).toBe('image/jpeg');

    const stream = result.getStream();
    stream.on('error', () => {});
    stream.destroy();
  });

  it('404s for a missing file', () => {
    expect(() => sut.serve('chat', '99999999-2222-4333-8444-555555555555.jpg')).toThrow(
      NotFoundException,
    );
  });

  it('refuses a public context, so /uploads content cannot be laundered through it', () => {
    expect(() => sut.serve('avatar', EXISTING)).toThrow(NotFoundException);
  });

  it.each([
    '../../../etc/passwd',
    '..%2f..%2fetc',
    'a/../../secret.jpg',
    'not-a-uuid.jpg',
    `${EXISTING}/../../secret`,
    '.env',
  ])('rejects traversal or non-generated filename %p', (filename) => {
    expect(() => sut.serve('chat', filename)).toThrow(NotFoundException);
  });
});
