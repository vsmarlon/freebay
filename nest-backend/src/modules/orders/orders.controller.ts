import {
  Controller,
  Body,
  Param,
  Query,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  CurrentUser,
  CurrentUserId,
  Paginated,
  PAGINATION_QUERIES,
} from '@/shared/decorators';
import { PageQuery } from '@/shared/core/pagination';
import { OrderRepository } from './domain/repositories/order.repository';
import { CreateOrderUseCase } from './usecases/create-order.usecase';
import { ConfirmDeliveryUseCase } from './usecases/confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './usecases/mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './usecases/mark-as-delivered.usecase';
import { CancelOrderUseCase } from './usecases/cancel-order.usecase';
import { CreateOrderDTO } from './dtos/order.dto';
import { AuthUser } from '@/shared/core/types';
import { left, isLeft } from '@/shared/core/either';
import { NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { getPlatformFeePercent } from '@/shared/core/platform-fee';

@ApiTags('Orders')
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly createOrderUseCase: CreateOrderUseCase,
    private readonly confirmDeliveryUseCase: ConfirmDeliveryUseCase,
    private readonly markAsShippedUseCase: MarkAsShippedUseCase,
    private readonly markAsDeliveredUseCase: MarkAsDeliveredUseCase,
    private readonly cancelOrderUseCase: CancelOrderUseCase,
  ) {}

  @PostAuth({
    summary: 'Create order',
    bodyType: CreateOrderDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
    errors: [{ status: 404, description: 'Product not found' }],
  })
  async create(@CurrentUserId() buyerId: string, @Body() body: CreateOrderDTO) {
    const productResult = await this.orderRepository.findProductForOrder(body.productId);
    if (isLeft(productResult)) return productResult;
    const product = productResult.value;
    if (!product) return left(new NotFoundError('Produto'));

    return this.createOrderUseCase.execute({
      buyerId,
      sellerId: product.sellerId,
      productId: product.id,
      amount: product.price,
      platformFeePercent: getPlatformFeePercent(),
    });
  }

  @GetAuth('my/purchases', { summary: 'Get my purchases', queries: PAGINATION_QUERIES })
  async getMyPurchases(@CurrentUserId() userId: string, @Paginated() page: PageQuery) {
    return this.orderRepository.findByBuyerId(userId, page);
  }

  @GetAuth('my/sales', { summary: 'Get my sales', queries: PAGINATION_QUERIES })
  async getMySales(@CurrentUserId() userId: string, @Paginated() page: PageQuery) {
    return this.orderRepository.findBySellerId(userId, page);
  }

  @GetAuth(':id', {
    summary: 'Get order by ID',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [
      { status: 404, description: 'Order not found' },
      { status: 403, description: 'Access denied' },
    ],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.orderRepository.findById(id);
    if (isLeft(result)) return result;
    if (!result.value) return left(new NotFoundError('Pedido'));

    const order = result.value;
    if (order.buyerId !== user.userId && order.sellerId !== user.userId && user.role !== 'ADMIN') {
      return left(new ForbiddenError('Você não tem permissão para visualizar este pedido'));
    }

    return { order };
  }

  @PatchAuth(':id/ship', {
    summary: 'Mark order as shipped',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async markAsShipped(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() sellerId: string) {
    return this.markAsShippedUseCase.execute({ orderId: id, sellerId });
  }

  @PatchAuth(':id/deliver', {
    summary: 'Mark order as delivered',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async markAsDelivered(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() buyerId: string) {
    return this.markAsDeliveredUseCase.execute({ orderId: id, buyerId });
  }

  @PatchAuth(':id/confirm', {
    summary: 'Confirm delivery (release escrow to seller)',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async confirmDelivery(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() buyerId: string) {
    return this.confirmDeliveryUseCase.execute({ orderId: id, buyerId });
  }

  @PatchAuth(':id/confirm-delivery', {
    summary: 'Confirm delivery (alias)',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async confirmDeliveryAlias(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() buyerId: string) {
    return this.confirmDelivery(id, buyerId);
  }

  @PatchAuth(':id/cancel', {
    summary: 'Cancel order',
    params: [{ name: 'id', description: 'Order UUID' }],
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async cancel(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.cancelOrderUseCase.execute({ orderId: id, userId });
  }

  @GetAuth({
    summary: 'List user orders',
    queries: [
      { name: 'role', required: false, description: 'Filter by role: "seller" or "buyer" (default)' },
      ...PAGINATION_QUERIES,
    ],
  })
  async findAll(
    @CurrentUserId() userId: string,
    @Paginated() page: PageQuery,
    @Query('role') role?: string,
  ) {
    return role === 'seller'
      ? this.orderRepository.findBySellerId(userId, page)
      : this.orderRepository.findByBuyerId(userId, page);
  }
}

