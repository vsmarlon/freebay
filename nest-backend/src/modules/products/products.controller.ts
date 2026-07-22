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
import { ProductsService } from './products.service';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { validateImageFile, MAX_IMAGE_SIZE } from '@/shared/utils/image-upload.utils';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  private readonly logger = new Logger(ProductsController.name);

  constructor(private readonly productsService: ProductsService) {}

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
    return this.productsService.findAll(query);
  }

  @Get(':id')
  @ApiDoc({
    summary: 'Get product by ID',
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_IMAGE_SIZE },
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
      return { success: false, error: { code: 'BAD_REQUEST', message: 'Imagem do produto é obrigatória' } };
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      return { success: false, error: { code: 'BAD_REQUEST', message: mimeError } };
    }

    return this.productsService.create(user, file, body);
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
    return this.productsService.delete(id, user.userId);
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
    return this.productsService.update(id, user.userId, body);
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
    return this.productsService.findMyProducts(user.userId);
  }
}
