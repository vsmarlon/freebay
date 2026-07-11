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
import { OrdersService } from './orders.service';
import { CreateOrderDTO } from './dtos/order.dto';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Orders')
@Controller('orders')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

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
    const productResult = await this.ordersService.findProductForOrder(body.productId);
    if (isLeft(productResult)) throw productResult.value;

    const product = productResult.value;
    if (!product) throw new AppError('NOT_FOUND', 'Produto não encontrado', 404);

    const result = await this.ordersService.create({
      buyerId: user.userId,
      sellerId: product.sellerId,
      productId: product.id,
      amount: product.price,
      platformFeePercent: 10,
    });

    if (isLeft(result)) throw result.value;
    return result.value;
  }

  @Get(':id')
  @ApiDoc({
    summary: 'Get order by ID',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const result = await this.ordersService.findOne(id);
    if (isLeft(result)) throw result.value;
    if (!result.value) throw new AppError('NOT_FOUND', 'Pedido não encontrado', 404);
    return { order: result.value };
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
    const result = await this.ordersService.markAsShipped({ orderId: id, sellerId: user.userId });
    if (isLeft(result)) throw result.value;
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
    const result = await this.ordersService.markAsDelivered({ orderId: id, buyerId: user.userId });
    if (isLeft(result)) throw result.value;
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
    const result = await this.ordersService.confirmDelivery({ orderId: id, buyerId: user.userId });
    if (isLeft(result)) throw result.value;
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
    const result = await this.ordersService.cancel({ orderId: id, userId: user.userId });
    if (isLeft(result)) throw result.value;
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
    const result = role === 'seller'
      ? await this.ordersService.findBySellerId(user.userId)
      : await this.ordersService.findByBuyerId(user.userId);
    if (isLeft(result)) throw result.value;
    return { orders: result.value };
  }

  @Get('my/purchases')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get my purchases',
    auth: true,
  })
  async getMyPurchases(@CurrentUser() user: AuthUser) {
    const result = await this.ordersService.findByBuyerId(user.userId);
    if (isLeft(result)) throw result.value;
    return { orders: result.value };
  }

  @Get('my/sales')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get my sales',
    auth: true,
  })
  async getMySales(@CurrentUser() user: AuthUser) {
    const result = await this.ordersService.findBySellerId(user.userId);
    if (isLeft(result)) throw result.value;
    return { orders: result.value };
  }
}
