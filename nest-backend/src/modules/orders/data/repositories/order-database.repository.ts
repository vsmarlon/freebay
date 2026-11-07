import { Injectable } from "@nestjs/common";
import { OrderStatus, Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from "@/shared/core/either";
import { CursorPage, PageQuery } from "@/shared/core/pagination";
import {
  OrderFullPayload,
  OrderProductPayload,
  CreateOrderTxData,
  ConfirmDeliveryData,
  CancelOrderTxData,
  RefundOrderTxData,
  ProductForOrder,
  CreateOrderPayload,
  SalesOrderCursor,
  SalesOrderStatus,
  StaleUnpaidOrder,
} from "../../types/order.types";
import { OrderReadRepository } from "./order-read.repository";
import { OrderReservationRepository } from "./order-reservation.repository";
import { OrderMutationRepository } from "./order-mutation.repository";

@Injectable()
export class OrderDatabaseRepository {
  private readonly reads: OrderReadRepository;
  private readonly reservations: OrderReservationRepository;
  private readonly mutations: OrderMutationRepository;

  constructor(private readonly prisma: PrismaService) {
    this.reads = new OrderReadRepository(prisma);
    this.reservations = new OrderReservationRepository(prisma);
    this.mutations = new OrderMutationRepository(prisma, this.reservations);
  }

  async findById(id: string): RepositoryResponse<OrderFullPayload | null> {
    return this.reads.findById(id);
  }

  async findProductForOrder(productId: string): RepositoryResponse<ProductForOrder | null> {
    return this.reads.findProductForOrder(productId);
  }

  async findByBuyerId(buyerId: string, page: PageQuery, status?: OrderStatus): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.reads.findByBuyerId(buyerId, page, status);
  }

  async findBySellerId(sellerId: string, page: PageQuery, status?: OrderStatus): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.reads.findBySellerId(sellerId, page, status);
  }

  async findSellerSales(sellerId: string, page: PageQuery, status: SalesOrderStatus | undefined, cursor: SalesOrderCursor | null): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.reads.findSellerSales(sellerId, page, status, cursor);
  }

  async countBySellerId(sellerId: string): RepositoryResponse<number> {
    return this.reads.countBySellerId(sellerId);
  }

  async countByBuyerId(buyerId: string): RepositoryResponse<number> {
    return this.reads.countByBuyerId(buyerId);
  }

  async findStaleUnpaidOrders(cutoff: Date): RepositoryResponse<StaleUnpaidOrder[]> {
    return this.reads.findStaleUnpaidOrders(cutoff);
  }

  async update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown> {
    return repositoryResponse(
      () => this.prisma.order.update({ where: { id }, data }),
      "Erro ao atualizar pedido",
    );
  }

  async createOrderWithReservation(data: CreateOrderTxData): RepositoryResponse<CreateOrderPayload> {
    return this.reservations.createOrderWithReservation(data);
  }

  async confirmDelivery(data: ConfirmDeliveryData): RepositoryResponse<boolean> {
    return this.mutations.confirmDelivery(data);
  }

  markDelivered(orderId: string): RepositoryResponse<boolean> {
    return this.mutations.markDelivered(orderId);
  }

  async cancelOrder(data: CancelOrderTxData): RepositoryResponse<boolean> {
    return this.mutations.cancelOrder(data);
  }

  claimCancellation(
    orderId: string,
    status: OrderStatus,
    reason: string,
    owner?: Parameters<OrderMutationRepository['claimCancellation']>[3],
  ): RepositoryResponse<boolean> {
    return this.mutations.claimCancellation(orderId, status, reason, owner);
  }

  claimCheckoutAbandoned(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<boolean> {
    return this.mutations.claimCheckoutAbandoned(orderId, tx);
  }

  markRefundPending(orderId: string, reason: string): RepositoryResponse<void> {
    return this.mutations.markRefundPending(orderId, reason);
  }

  markShipped(orderId: string): RepositoryResponse<boolean> {
    return this.mutations.markShipped(orderId);
  }

  async refundOrder(data: RefundOrderTxData): RepositoryResponse<boolean> {
    return this.mutations.refundOrder(data);
  }

  async confirm(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<boolean> {
    return this.mutations.confirm(orderId, tx);
  }

  async cancel(orderId: string, tx?: Prisma.TransactionClient): RepositoryResponse<boolean> {
    return this.mutations.cancel(orderId, tx);
  }
}
