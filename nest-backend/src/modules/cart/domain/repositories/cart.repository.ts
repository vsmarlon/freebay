import { Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { CartItemPayload, ProductBrief, ReserveOrderInput } from '../../types/cart.types';

export abstract class CartRepository {
  abstract findProductById(productId: string): RepositoryResponse<ProductBrief | null>;
  abstract findItem(userId: string, productId: string): RepositoryResponse<{ id: string; quantity: number } | null>;
  abstract addOrIncrement(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }>;
  abstract updateQuantity(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }>;
  abstract remove(userId: string, productId: string): RepositoryResponse<void>;
  abstract clear(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
  abstract getUserCart(userId: string): RepositoryResponse<CartItemPayload[]>;
  abstract findUserCpf(userId: string): RepositoryResponse<string | null>;
  abstract reserveAndCreateOrder(
    data: ReserveOrderInput,
    tx: Prisma.TransactionClient,
  ): Promise<{ id: string }>;
  abstract restoreOrderReservation(
    orderId: string,
    productId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void>;
}
