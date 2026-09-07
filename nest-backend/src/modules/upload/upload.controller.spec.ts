import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, CanActivate, ExecutionContext } from '@nestjs/common';
import { rmSync } from 'fs';
import { join } from 'path';
import { UploadController, isValidContext } from './upload.controller';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';

class MockJwtGuard implements CanActivate {
  canActivate(_context: ExecutionContext): boolean {
    return true;
  }
}

describe('UploadController', () => {
  let sut: UploadController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UploadController],
    })
      .overrideGuard(JwtAuthGuard)
      .useClass(MockJwtGuard)
      .compile();
    sut = module.get<UploadController>(UploadController);
  });

  it('stores a chat attachment privately, never under the public /uploads root', () => {
    const file = {
      mimetype: 'image/jpeg',
      buffer: Buffer.from('img'),
      size: 3,
    } as Express.Multer.File;

    const result = sut.upload(file, 'chat');

    expect(result.url).toMatch(
      /^\/media\/chat\/[0-9a-f-]{36}\.jpg$/,
    );
    rmSync(join(process.cwd(), result.url.replace('/media/', 'private-uploads/')));
  });

  it('stores a public context under /uploads', () => {
    const file = {
      mimetype: 'image/jpeg',
      buffer: Buffer.from('img'),
      size: 3,
    } as Express.Multer.File;

    const result = sut.upload(file, 'avatar');

    expect(result.url).toMatch(/^\/uploads\/avatar\/[0-9a-f-]{36}\.jpg$/);
    rmSync(join(process.cwd(), result.url.replace('/uploads/', 'uploads/')));
  });

  it('throws BadRequestException when no file', () => {
    expect(() => sut.upload(undefined, 'chat')).toThrow(BadRequestException);
  });

  it('throws BadRequestException for invalid context', () => {
    const file = { filename: 'abc.jpg' } as Express.Multer.File;
    expect(() => sut.upload(file, 'invalid')).toThrow(BadRequestException);
  });

  it('throws BadRequestException for path-traversal context', () => {
    const file = { filename: 'abc.jpg' } as Express.Multer.File;
    expect(() => sut.upload(file, '../../etc')).toThrow(BadRequestException);
  });

  describe('isValidContext', () => {
    it.each(['chat', 'background', 'post', 'avatar'])('accepts %s', (context) => {
      expect(isValidContext(context)).toBe(true);
    });

    it.each([
      '../../etc',
      '..',
      'chat/../../etc',
      '/absolute',
      'misc',
      '',
      undefined,
      null,
      123,
    ])('rejects %p', (context) => {
      expect(isValidContext(context)).toBe(false);
    });
  });
});
