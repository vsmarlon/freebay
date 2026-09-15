import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate, ExecutionContext, NotFoundException, StreamableFile } from '@nestjs/common';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { join } from 'path';
import { MediaController } from './media.controller';
import { MediaAccessService } from './services/media-access.service';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PRIVATE_UPLOAD_ROOT } from '@/shared/utils/file.utils';

class MockJwtGuard implements CanActivate {
  canActivate(_context: ExecutionContext): boolean {
    return true;
  }
}

const EXISTING = '11111111-2222-4333-8444-555555555555.jpg';
const VIEWER = 'viewer-user-id';

const drain = (stream: NodeJS.ReadableStream): Promise<void> =>
  new Promise<void>((resolve, reject) => {
    stream.once('end', resolve);
    stream.once('error', reject);
    stream.resume();
  });

describe('MediaController', () => {
  let sut: MediaController;
  let mediaAccess: { canRead: jest.Mock };
  const dir = join(process.cwd(), PRIVATE_UPLOAD_ROOT, 'chat');

  beforeAll(() => {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, EXISTING), 'bytes');
  });

  afterAll(() => {
    rmSync(join(dir, EXISTING), { force: true });
  });

  beforeEach(async () => {
    mediaAccess = { canRead: jest.fn().mockResolvedValue(true) };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [MediaController],
      providers: [{ provide: MediaAccessService, useValue: mediaAccess }],
    })
      .overrideGuard(JwtAuthGuard)
      .useClass(MockJwtGuard)
      .compile();
    sut = module.get<MediaController>(MediaController);
  });

  it('streams an existing private file to an authorized participant', async () => {
    const result = await sut.serve(VIEWER, 'chat', EXISTING);
    expect(result).toBeInstanceOf(StreamableFile);
    expect(result.options.type).toBe('image/jpeg');

    await drain(result.getStream());
  });

  it('404s for a caller the access service refuses', async () => {
    mediaAccess.canRead.mockResolvedValue(false);
    await expect(sut.serve(VIEWER, 'chat', EXISTING)).rejects.toThrow(NotFoundException);
  });

  it('authorizes against the requesting user, not just the filename', async () => {
    const result = await sut.serve(VIEWER, 'chat', EXISTING);
    await drain(result.getStream());
    expect(mediaAccess.canRead).toHaveBeenCalledWith(VIEWER, 'chat', EXISTING);
  });

  it('404s for a missing file', async () => {
    await expect(
      sut.serve(VIEWER, 'chat', '99999999-2222-4333-8444-555555555555.jpg'),
    ).rejects.toThrow(NotFoundException);
  });

  it('refuses a public context, so /uploads content cannot be laundered through it', async () => {
    await expect(sut.serve(VIEWER, 'avatar', EXISTING)).rejects.toThrow(NotFoundException);
  });

  it.each([
    '../../../etc/passwd',
    '..%2f..%2fetc',
    'a/../../secret.jpg',
    'not-a-uuid.jpg',
    `${EXISTING}/../../secret`,
    '.env',
  ])('rejects traversal or non-generated filename %p', async (filename) => {
    await expect(sut.serve(VIEWER, 'chat', filename)).rejects.toThrow(NotFoundException);
  });

  it('rejects a bad filename before consulting the access service', async () => {
    await expect(sut.serve(VIEWER, 'chat', '.env')).rejects.toThrow(NotFoundException);
    expect(mediaAccess.canRead).not.toHaveBeenCalled();
  });

  it('handles RFC 7233 range requests with HTTP 206 and Content-Range', async () => {
    const headers: Record<string, string> = {};
    let status = 200;
    const req = { headers: { range: 'bytes=1-3' } };
    const res = {
      setHeader(name: string, value: string) {
        headers[name] = value;
      },
      status(code: number) {
        status = code;
      },
    };

    const result = await sut.serve(VIEWER, 'chat', EXISTING, req, res);
    expect(status).toBe(206);
    expect(headers['Accept-Ranges']).toBe('bytes');
    expect(headers['Content-Range']).toBe('bytes 1-3/5');
    expect(headers['Content-Length']).toBe('3');
    expect(result.options.length).toBe(3);

    await drain(result.getStream());
  });

  it('returns HTTP 416 for an unsatisfiable range request', async () => {
    const headers: Record<string, string> = {};
    let status = 200;
    const req = { headers: { range: 'bytes=10-20' } };
    const res = {
      setHeader(name: string, value: string) {
        headers[name] = value;
      },
      status(code: number) {
        status = code;
      },
    };

    const result = await sut.serve(VIEWER, 'chat', EXISTING, req, res);
    expect(status).toBe(416);
    expect(headers['Content-Range']).toBe('bytes */5');

    await drain(result.getStream());
  });

  it('sets Accept-Ranges and Content-Length on full file responses', async () => {
    const headers: Record<string, string> = {};
    const res = {
      setHeader(name: string, value: string) {
        headers[name] = value;
      },
    };

    const result = await sut.serve(VIEWER, 'chat', EXISTING, undefined, res);
    expect(headers['Accept-Ranges']).toBe('bytes');
    expect(headers['Content-Length']).toBe('5');
    expect(result.options.length).toBe(5);

    await drain(result.getStream());
  });
});
