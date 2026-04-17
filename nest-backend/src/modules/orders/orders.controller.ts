import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { CreateOrderUseCase, ConfirmDeliveryUseCase } from './usecases/order.usecase';
import { CreateOrderDTO, createOrderSchema } from './dtos/order.dto';
import { PrismaOrderRepository } from './repositories/order.repository';
import { PrismaProductRepository } from '../products/repositories/product.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Controller('orders')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class OrdersController {
  constructor(
    private readonly createOrderUseCase: CreateOrderUseCase,
    private readonly confirmDeliveryUseCase: ConfirmDeliveryUseCase,
    private readonly orderRepository: PrismaOrderRepository,
    private readonly productRepository: PrismaProductRepository,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@CurrentUser() user: AuthUser, @Body(new ZodValidationPipe(createOrderSchema)) body: CreateOrderDTO) {
    const userId = user.userId;
    const product = await this.productRepository.findById(body.productId);

    if (!product) {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado'));
    }

    const result = await this.createOrderUseCase.execute({
      buyerId: userId,
      sellerId: product.sellerId,
      productId: product.id,
      amount: product.price,
      platformFeePercent: 10,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const order = await this.orderRepository.findById(id);
    if (!order) {
      return left(new AppError('NOT_FOUND', 'Pedido não encontrado'));
    }
    return { order };
  }

  @Post(':id/confirm')
  async confirmDelivery(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.confirmDeliveryUseCase.execute({ orderId: id, buyerId: userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get()
  async findAll(@CurrentUser() user: AuthUser, @Query('role') role?: string) {
    const userId = user.userId;
    const orders = role === 'seller'
      ? await this.orderRepository.findBySellerId(userId)
      : await this.orderRepository.findByBuyerId(userId);
    return { orders };
  }
}
