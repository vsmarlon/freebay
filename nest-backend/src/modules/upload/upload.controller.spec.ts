import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, CanActivate, ExecutionContext } from '@nestjs/common';
import { UploadController } from './upload.controller';
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

  it('returns relative url when file is provided', () => {
    const file = {
      filename: 'abc123.jpg',
      mimetype: 'image/jpeg',
    } as Express.Multer.File;

    const result = sut.upload(file, 'chat');

    expect(result).toEqual({ url: '/uploads/chat/abc123.jpg' });
  });

  it('throws BadRequestException when no file', () => {
    expect(() => sut.upload(undefined as any, 'chat')).toThrow(BadRequestException);
  });

  it('throws BadRequestException for invalid context', () => {
    const file = { filename: 'abc.jpg' } as Express.Multer.File;
    expect(() => sut.upload(file, 'invalid')).toThrow(BadRequestException);
  });
});
