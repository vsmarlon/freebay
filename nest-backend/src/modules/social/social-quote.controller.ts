import { Body, Controller, Headers, HttpStatus, UploadedFile, UseInterceptors } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { isUUID } from 'class-validator';
import { PostAuth, CurrentUserId } from '@/shared/decorators';
import { BadRequestError } from '@/shared/core/errors';
import { left } from '@/shared/core/either';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import { CreateQuoteDTO } from './dtos/social.dto';
import { CreateQuoteUseCase } from './usecases/create-quote.usecase';
import { BoundedMultipartInterceptor } from '@/shared/interceptors/bounded-multipart.interceptor';

@ApiTags('Social')
@Controller('social')
export class SocialQuoteController {
  constructor(private readonly createQuoteUseCase: CreateQuoteUseCase) {}

  @PostAuth('quotes', { summary: 'Create an idempotent quote post', bodyType: CreateQuoteDTO, responseStatus: 201, httpCode: HttpStatus.CREATED })
  @UseInterceptors(BoundedMultipartInterceptor('image', 1, 20 * 1024 * 1024))
  async createQuote(
    @CurrentUserId() userId: string,
    @Body() body: CreateQuoteDTO,
    @UploadedFile() image: Express.Multer.File | undefined,
    @Headers('Idempotency-Key') idempotencyKey?: string,
  ) {
    const headerKey = idempotencyKey?.trim();
    if (headerKey && !isUUID(headerKey)) return left(new BadRequestError('Idempotency-Key must be a UUID'));
    if (headerKey && body.clientRequestId && headerKey !== body.clientRequestId) {
      return left(new BadRequestError('Idempotency-Key and clientRequestId must match'));
    }
    if (image) {
      const mimeError = validateImageFile(image, 20 * 1024 * 1024);
      if (mimeError) return left(new BadRequestError(mimeError));
    }
    const imageBlurHash = image ? await generateImageBlurHash(image.buffer) : undefined;
    const result = await this.createQuoteUseCase.execute({
      userId,
      ...body,
      clientRequestId: headerKey ?? body.clientRequestId,
      image,
      imageBlurHash,
    });
    return result;
  }
}
