import { RepositoryResponse } from '@/shared/core/either';
import { CartItemPayload, ProductBrief } from '../../types/cart.types';

export abstract class CartRepository {
  abstract findProductById(productId: string): RepositoryResponse<ProductBrief | null>;
  abstract findItem(userId: string, productId: string): RepositoryResponse<{ id: string; quantity: number } | null>;
  abstract addOrIncrement(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }>;
  abstract updateQuantity(userId: string, productId: string, quantity: number): RepositoryResponse<{ id: string; quantity: number }>;
  abstract remove(userId: string, productId: string): RepositoryResponse<void>;
  abstract clear(userId: string): RepositoryResponse<void>;
  abstract getUserCart(userId: string): RepositoryResponse<CartItemPayload[]>;
  abstract findUserCpf(userId: string): RepositoryResponse<string | null>;
  abstract createOrderFromCheckout(data: {
    userId: string;
    sellerId: string;
    productId: string;
    quantity: number;
    amount: number;
    platformFee: number;
    sellerAmount: number;
  }): RepositoryResponse<{ id: string }>;
  abstract rollbackOrderReservation(orderId: string, productId: string): RepositoryResponse<void>;
}
