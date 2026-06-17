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
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import {
  CreateOrderUseCase,
  ConfirmDeliveryUseCase,
  MarkAsShippedUseCase,
  MarkAsDeliveredUseCase,
  CancelOrderUseCase,
} from './usecases/order.usecase';
import { CreateOrderDTO, OrderResponse } from './dtos/order.dto';
import { PrismaOrderRepository } from './repositories/order.repository';
import { PrismaProductRepository } from '../products/repositories/product.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Orders')
@Controller('orders')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class OrdersController {
  constructor(
    private readonly createOrderUseCase: CreateOrderUseCase,
    private readonly confirmDeliveryUseCase: ConfirmDeliveryUseCase,
    private readonly markAsShippedUseCase: MarkAsShippedUseCase,
    private readonly markAsDeliveredUseCase: MarkAsDeliveredUseCase,
    private readonly cancelOrderUseCase: CancelOrderUseCase,
    private readonly orderRepository: PrismaOrderRepository,
    private readonly productRepository: PrismaProductRepository,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create order',
    bodyType: CreateOrderDTO,
    responseStatus: 201,
    auth: true,
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async create(@CurrentUser() user: AuthUser, @Body() body: CreateOrderDTO) {
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
  @ApiDoc({
    summary: 'Get order by ID',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const order = await this.orderRepository.findById(id);
    if (!order) {
      return left(new AppError('NOT_FOUND', 'Pedido não encontrado'));
    }
    return { order };
  }

  @Post(':id/ship')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Mark order as shipped',
    auth: true,
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async markAsShipped(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.markAsShippedUseCase.execute({ orderId: id, sellerId: user.userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post(':id/deliver')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Mark order as delivered',
    auth: true,
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async markAsDelivered(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.markAsDeliveredUseCase.execute({ orderId: id, buyerId: user.userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post(':id/confirm')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Confirm delivery (release escrow to seller)',
    auth: true,
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async confirmDelivery(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.confirmDeliveryUseCase.execute({ orderId: id, buyerId: userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post(':id/confirm-delivery')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Confirm delivery (alias)',
    auth: true,
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async confirmDeliveryAlias(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    return this.confirmDelivery(id, user);
  }

  @Post(':id/cancel')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Cancel order',
    auth: true,
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async cancel(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.cancelOrderUseCase.execute({ orderId: id, userId: user.userId });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'List user orders',
    auth: true,
    queries: [
      { name: 'role', required: false, description: 'Filter by role: "seller" or "buyer" (default)' },
    ],
  })
  async findAll(@CurrentUser() user: AuthUser, @Query('role') role?: string) {
    const userId = user.userId;
    const orders = role === 'seller'
      ? await this.orderRepository.findBySellerId(userId)
      : await this.orderRepository.findByBuyerId(userId);
    return { orders };
  }

  @Get('my/purchases')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get my purchases',
    auth: true,
  })
  async getMyPurchases(@CurrentUser() user: AuthUser) {
    const orders = await this.orderRepository.findByBuyerId(user.userId);
    return { orders };
  }

  @Get('my/sales')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get my sales',
    auth: true,
  })
  async getMySales(@CurrentUser() user: AuthUser) {
    const orders = await this.orderRepository.findBySellerId(user.userId);
    return { orders };
  }
}
