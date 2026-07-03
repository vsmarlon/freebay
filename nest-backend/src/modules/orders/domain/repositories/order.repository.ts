import { RepositoryResponse } from '@/shared/core/either';
import { OrderFullPayload, OrderProductPayload } from '../../types/order.types';

export interface CreateOrderTxData {
  buyerId: string;
  sellerId: string;
  productId: string;
  amount: number;
  platformFee: number;
  sellerAmount: number;
}

export interface ConfirmDeliveryData {
  orderId: string;
  sellerId: string;
  sellerAmount: number;
}

export interface CancelOrderTxData {
  orderId: string;
  productId: string;
  buyerId: string;
  amount: number;
  status: string;
  quantity: number;
}

export abstract class OrderRepository {
  abstract findById(id: string): RepositoryResponse<OrderFullPayload | null>;
  abstract findByBuyerId(buyerId: string): RepositoryResponse<OrderProductPayload[]>;
  abstract findBySellerId(sellerId: string): RepositoryResponse<OrderProductPayload[]>;
  abstract countBySellerId(sellerId: string): RepositoryResponse<number>;
  abstract countByBuyerId(buyerId: string): RepositoryResponse<number>;
  abstract update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown>;
  abstract createOrderWithReservation(data: CreateOrderTxData): RepositoryResponse<{ id: string }>;
  abstract confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<void>;
  abstract activateEscrow(orderId: string, sellerId: string, sellerAmount: number): RepositoryResponse<void>;
  abstract cancelOrder(data: CancelOrderTxData): RepositoryResponse<void>;
}
