import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseInterceptors,
  UploadedFile,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { validateImageFile, MAX_IMAGE_SIZE } from '@/shared/utils/image-upload.utils';
import { toDataUri } from '@/shared/utils/file.utils';
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

  @Get()
  @ApiDoc({
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

  @Get(':id')
  @ApiDoc({
    summary: 'Get product by ID',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async findOne(@Param('id') id: string) {
    return this.getProductByIdUseCase.execute(id);
  }

  @Post()
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_IMAGE_SIZE },
    }),
  )
  @Authenticated({
    summary: 'Create a product',
    description: 'Creates a new product listing with image',
    bodyType: CreateProductDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  async create(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreateProductDTO,
  ) {
    if (!file) {
      return left(new BadRequestError('Imagem do produto é obrigatória'));
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      return left(new BadRequestError(mimeError));
    }

    const dataUri = toDataUri(file);
    return this.createProductUseCase.execute({
      sellerId: user.userId,
      ...body,
      images: [dataUri],
    });
  }

  @Delete(':id')
  @Authenticated({
    summary: 'Delete a product',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async delete(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.deleteProductUseCase.execute({ productId: id, userId: user.userId });
  }

  @Patch(':id')
  @Authenticated({
    summary: 'Update a product',
    bodyType: UpdateProductDTO,
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async update(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body() body: UpdateProductDTO,
  ) {
    return this.updateProductUseCase.execute({ productId: id, userId: user.userId, ...body });
  }

  @Get('mine/all')
  @Authenticated({
    summary: 'Get my products',
    description: 'Returns all products for the current authenticated user',
  })
  async findMyProducts(@CurrentUser() user: AuthUser) {
    return this.getMyProductsUseCase.execute(user.userId);
  }
}
