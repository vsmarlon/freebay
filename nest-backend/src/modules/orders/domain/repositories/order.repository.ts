import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { Prisma } from '@prisma/client';
import {
  OrderFullPayload,
  OrderProductPayload,
  CreateOrderTxData,
  ConfirmDeliveryData,
  CancelOrderTxData,
  ProductForOrder,
} from '../../types/order.types';

export abstract class OrderRepository {
  abstract findById(id: string): RepositoryResponse<OrderFullPayload | null>;
  abstract findProductForOrder(productId: string): RepositoryResponse<ProductForOrder | null>;
  abstract findByBuyerId(
    buyerId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>>;
  abstract findBySellerId(
    sellerId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>>;
  abstract countBySellerId(sellerId: string): RepositoryResponse<number>;
  abstract countByBuyerId(buyerId: string): RepositoryResponse<number>;
  abstract update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown>;
  abstract createOrderWithReservation(data: CreateOrderTxData): RepositoryResponse<{ id: string }>;
  abstract confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<void>;
  abstract cancelOrder(data: CancelOrderTxData): RepositoryResponse<void>;
  abstract confirm(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
  abstract cancel(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
}
