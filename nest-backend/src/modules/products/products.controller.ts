import {
  Controller,
  Body,
  Param,
  Query,
  UseInterceptors,
  UploadedFile,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import {
  GetAuth,
  GetPublic,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from '@/shared/decorators';
import { validateImageFile, MAX_IMAGE_SIZE } from '@/shared/utils/image-upload.utils';
import { deleteUpload, saveUpload } from '@/shared/utils/file.utils';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import { left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
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
    description: 'Creates a new product listing with image',
    bodyType: CreateProductDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_IMAGE_SIZE },
    }),
  )
  async create(
    @CurrentUserId() sellerId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreateProductDTO,
  ) {
    if (!file) {
      return left(new BadRequestError('Imagem do produto é obrigatória'));
    }

    if (file) {
      const mimeError = validateImageFile(file);
      if (mimeError) return left(new BadRequestError(mimeError));
    }

    const imageUrl = saveUpload(file, 'product');
    const imageBlurHash = await generateImageBlurHash(file.buffer);
    try {
      const result = await this.createProductUseCase.execute({
        sellerId,
        ...body,
        images: [imageUrl],
        imageBlurHash,
      });
      if (result.isLeft()) deleteUpload(imageUrl);
      return result;
    } catch (error) {
      deleteUpload(imageUrl);
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
