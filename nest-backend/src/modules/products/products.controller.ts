import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  UploadedFile,
  UseInterceptors,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CreateProductUseCase, DeleteProductUseCase, UpdateProductUseCase } from './usecases/product.usecase';
import { CreateProductDTO, UpdateProductDTO } from './dtos/product.dto';
import { PrismaProductRepository } from './repositories/product.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { validateImageFile } from '@/shared/utils/image-upload.utils';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  private readonly logger = new Logger(ProductsController.name);

  constructor(
    private readonly createProductUseCase: CreateProductUseCase,
    private readonly updateProductUseCase: UpdateProductUseCase,
    private readonly deleteProductUseCase: DeleteProductUseCase,
    private readonly productRepository: PrismaProductRepository,
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
    ],
  })
  async findAll(
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('category') category?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
  ) {
    const products = await this.productRepository.findMany({
      cursor,
      limit: limit ? parseInt(limit) : undefined,
      search,
      categoryId: category,
      minPrice: minPrice ? parseInt(minPrice) : undefined,
      maxPrice: maxPrice ? parseInt(maxPrice) : undefined,
    });

    return {
      products,
      nextCursor:
        products.length === (limit ? parseInt(limit) : 20)
          ? products[products.length - 1]?.id
          : null,
    };
  }

  @Get(':id')
  @ApiDoc({
    summary: 'Get product by ID',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async findOne(@Param('id') id: string) {
    const product = await this.productRepository.findById(id);
    if (!product) {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado'));
    }
    return { product };
  }

  @Post()
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 1000000 },
    }),
  )
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create a product',
    description: 'Creates a new product listing with image',
    bodyType: CreateProductDTO,
    auth: true,
    responseStatus: 201,
  })
  async create(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreateProductDTO,
  ) {
    if (!file) {
      this.logger.warn('Create product called without image file');
      return left(new AppError('BAD_REQUEST', 'Imagem do produto é obrigatória'));
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      return left(new AppError('BAD_REQUEST', mimeError));
    }

    this.logger.debug(
      `Create product request sellerId=${user.userId} title=${body.title} price=${body.price} categoryId=${body.categoryId} fileSize=${file.size}`,
    );

    const userId = user.userId;
    const result = await this.createProductUseCase.execute({
      sellerId: userId,
      ...body,
      images: [this.toDataUri(file)],
    });

    if (result.isLeft()) {
      this.logger.warn(`Create product failed: ${result.value.code} - ${result.value.message}`);
      return left(new AppError(result.value.code, result.value.message));
    }

    this.logger.debug(`Create product succeeded id=${result.value.id}`);
    return result.value;
  }

  private toDataUri(file: Express.Multer.File): string {
    return `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Delete a product',
    auth: true,
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async delete(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.deleteProductUseCase.execute({ productId: id, userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    return result.value;
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Update a product',
    bodyType: UpdateProductDTO,
    auth: true,
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async update(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body() body: UpdateProductDTO,
  ) {
    const result = await this.updateProductUseCase.execute({
      productId: id,
      userId: user.userId,
      ...body,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }

    return result.value;
  }

  @Get('mine/all')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get my products',
    description: 'Returns all products for the current authenticated user',
    auth: true,
  })
  async findMyProducts(@CurrentUser() user: AuthUser) {
    const sellerId = user.userId;
    const products = await this.productRepository.findBySellerId(sellerId);
    return { products };
  }
}
