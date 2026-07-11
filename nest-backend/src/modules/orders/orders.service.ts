import { Injectable } from '@nestjs/common';
import { CreateOrderUseCase } from './usecases/create-order.usecase';
import { ConfirmDeliveryUseCase } from './usecases/confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './usecases/mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './usecases/mark-as-delivered.usecase';
import { CancelOrderUseCase } from './usecases/cancel-order.usecase';
import { OrderRepository } from './domain/repositories/order.repository';
import { CreateOrderInput, ConfirmDeliveryInput, MarkAsShippedInput, MarkAsDeliveredInput, CancelOrderInput } from './dtos/order.dto';

@Injectable()
export class OrdersService {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly createOrderUseCase: CreateOrderUseCase,
    private readonly confirmDeliveryUseCase: ConfirmDeliveryUseCase,
    private readonly markAsShippedUseCase: MarkAsShippedUseCase,
    private readonly markAsDeliveredUseCase: MarkAsDeliveredUseCase,
    private readonly cancelOrderUseCase: CancelOrderUseCase,
  ) {}

  async findOne(id: string) {
    return this.orderRepository.findById(id);
  }

  async findProductForOrder(productId: string) {
    return this.orderRepository.findProductForOrder(productId);
  }

  async findByBuyerId(buyerId: string) {
    return this.orderRepository.findByBuyerId(buyerId);
  }

  async findBySellerId(sellerId: string) {
    return this.orderRepository.findBySellerId(sellerId);
  }

  async create(input: CreateOrderInput) {
    return this.createOrderUseCase.execute(input);
  }

  async confirmDelivery(input: ConfirmDeliveryInput) {
    return this.confirmDeliveryUseCase.execute(input);
  }

  async markAsShipped(input: MarkAsShippedInput) {
    return this.markAsShippedUseCase.execute(input);
  }

  async markAsDelivered(input: MarkAsDeliveredInput) {
    return this.markAsDeliveredUseCase.execute(input);
  }

  async cancel(input: CancelOrderInput) {
    return this.cancelOrderUseCase.execute(input);
  }
}
