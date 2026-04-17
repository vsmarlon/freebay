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
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CreateProductUseCase, DeleteProductUseCase, UpdateProductUseCase } from './usecases/product.usecase';
import { CreateProductDTO, UpdateProductDTO, createProductSchema, updateProductSchema } from './dtos/product.dto';
import { PrismaProductRepository } from './repositories/product.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

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
  async create(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body(new ZodValidationPipe(createProductSchema)) body: CreateProductDTO,
  ) {
    if (!file) {
      this.logger.warn('Create product called without image file');
      return left(new AppError('BAD_REQUEST', 'Imagem do produto é obrigatória'));
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
  async update(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(updateProductSchema)) body: UpdateProductDTO,
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
  async findMyProducts(@CurrentUser() user: AuthUser) {
    const sellerId = user.userId;
    const products = await this.productRepository.findBySellerId(sellerId);
    return { products };
  }
}
