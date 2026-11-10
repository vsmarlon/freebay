import {
  Controller,
  Body,
  Param,
  Query,
  UseInterceptors,
  UploadedFiles,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BoundedMultipartInterceptor } from '@/shared/interceptors/bounded-multipart.interceptor';
import { THROTTLE_TTL_MINUTE_MS } from '@/shared/http/throttle.constants';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import {
  GetAuth,
  GetPublic,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from '@/shared/decorators';
import { validateMediaFile, MAX_MEDIA_SIZE } from '@/shared/utils/image-upload.utils';
import { deleteUpload, saveUpload } from '@/shared/utils/file.utils';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import { left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { parsePublicationMedia, validatePublicationMediaFiles } from '@/shared/media/publication-media';

const PUBLICATION_UPLOAD_MAX_BYTES = 100 * 1024 * 1024;
const PUBLICATION_METADATA_MAX_BYTES = 256 * 1024;
import { CreateProductUseCase } from './usecases/create-product/create-product.usecase';
import { UpdateProductUseCase } from './usecases/update-product/update-product.usecase';
import { DeleteProductUseCase } from './usecases/delete-product/delete-product.usecase';
import { GetProductsUseCase } from './usecases/get-products/get-products.usecase';
import { GetProductByIdUseCase } from './usecases/get-products/get-product-by-id.usecase';
import { GetMyProductsUseCase } from './usecases/get-products/get-my-products.usecase';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(
    private readonly createProductUseCase: CreateProductUseCase,
    private readonly updateProductUseCase: UpdateProductUseCase,
    private readonly deleteProductUseCase: DeleteProductUseCase,
    private readonly getProductsUseCase: GetProductsUseCase,
    private readonly getProductByIdUseCase: GetProductByIdUseCase,
    private readonly getMyProductsUseCase: GetMyProductsUseCase,
  ) {}

  @GetPublic({
    summary: 'List products',
    description: 'Search and filter products with cursor pagination',
    queries: [
      { name: 'cursor', required: false, description: 'Pagination cursor' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'search', required: false, description: 'Search query' },
      { name: 'category', required: false, description: 'Category UUID filter' },
      { name: 'minPrice', required: false, description: 'Minimum price in cents' },
      { name: 'maxPrice', required: false, description: 'Maximum price in cents' },
      { name: 'condition', required: false, description: 'NEW or USED' },
      { name: 'sort', required: false, description: 'recent, price_asc, price_desc or popular' },
    ],
  })
  async findAll(@Query() query: ProductQueryDTO) {
    return this.getProductsUseCase.execute(query);
  }

  @GetAuth('mine/all', 'Get my products')
  async findMyProducts(@CurrentUserId() userId: string) {
    return this.getMyProductsUseCase.execute(userId);
  }

  @GetPublic(':id', {
    summary: 'Get product by ID',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.getProductByIdUseCase.execute(id);
  }

  @PostAuth({
    summary: 'Create a product',
    description: 'Creates a product listing with 1 to 10 ordered images or videos',
    bodyType: CreateProductDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @UseInterceptors(
    BoundedMultipartInterceptor('files', 20, PUBLICATION_UPLOAD_MAX_BYTES, PUBLICATION_METADATA_MAX_BYTES, MAX_MEDIA_SIZE),
  )
  async create(
    @CurrentUserId() sellerId: string,
    @UploadedFiles() files: Express.Multer.File[] = [],
    @Body() body: CreateProductDTO,
  ) {
    if (files.length === 0) return left(new BadRequestError('Ao menos uma mídia do produto é obrigatória'));
    for (const file of files) {
      const mimeError = validateMediaFile(file);
      if (mimeError) return left(new BadRequestError(mimeError));
    }
    let descriptors;
    try {
      descriptors = parsePublicationMedia(body.mediaMetadata, files.length);
      validatePublicationMediaFiles(descriptors, files);
    } catch (error) {
      return left(new BadRequestError(error instanceof Error ? error.message : 'Metadados de mídia inválidos'));
    }
    const savedUrls: string[] = [];
    try {
      for (const file of files) savedUrls.push(saveUpload(file, 'product'));
      const media = await Promise.all(descriptors.map(async (descriptor) => {
        const blurFile = files[descriptor.thumbnailFileIndex ?? descriptor.fileIndex];
        return {
          url: savedUrls[descriptor.fileIndex],
          ...(descriptor.thumbnailFileIndex == null ? {} : { thumbnailUrl: savedUrls[descriptor.thumbnailFileIndex] }),
          type: descriptor.type,
          blurHash: await generateImageBlurHash(blurFile.buffer),
          altText: descriptor.altText,
          durationMs: descriptor.durationMs,
          coverTimestampMs: descriptor.coverTimestampMs,
          hotspots: descriptor.hotspots,
        };
      }));
      const { mediaMetadata: _mediaMetadata, ...product } = body;
      const result = await this.createProductUseCase.execute({
        sellerId,
        ...product,
        media,
      });
      if (result.isLeft()) savedUrls.forEach(deleteUpload);
      return result;
    } catch (error) {
      savedUrls.forEach(deleteUpload);
      throw error;
    }
  }

  @PatchAuth(':id/delete', {
    summary: 'Soft-delete a product',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async delete(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.deleteProductUseCase.execute({ productId: id, userId });
  }

  @PatchAuth(':id', {
    summary: 'Update a product',
    bodyType: UpdateProductDTO,
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
    @Body() body: UpdateProductDTO,
  ) {
    return this.updateProductUseCase.execute({ productId: id, userId, ...body });
  }
}
