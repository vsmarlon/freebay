import { OrderStatus, Prisma } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { RepositoryResponse } from "@/shared/core/either";
import { buildIdCursorPage, CursorPage, PageQuery, encodeCursor } from "@/shared/core/pagination";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import {
  OrderProductPayload,
  OrderFullPayload,
  ProductForOrder,
  ORDER_INCLUDE_FULL,
  ORDER_INCLUDE_PRODUCT,
  SalesOrderCursor,
  SalesOrderStatus,
} from "../../types/order.types";

export class OrderReadRepository {
  constructor(private readonly prisma: PrismaService) {}
  async findById(id: string): RepositoryResponse<OrderFullPayload | null> {
    return repositoryResponse(
      () =>
        this.prisma.order.findUnique({
          where: { id },
          include: ORDER_INCLUDE_FULL,
        }),
      "Erro ao buscar pedido",
    );
  }

  async findProductForOrder(
    productId: string,
  ): RepositoryResponse<ProductForOrder | null> {
    return repositoryResponse(
      () =>
        this.prisma.product.findUnique({
          where: { id: productId },
          select: { id: true, sellerId: true, price: true },
        }),
      "Erro ao buscar produto",
    );
  }

  async findByBuyerId(
    buyerId: string,
    page: PageQuery,
    status?: OrderStatus,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.findOrderPage({ buyerId, ...(status ? { status } : {}) }, page);
  }

  async findBySellerId(
    sellerId: string,
    page: PageQuery,
    status?: OrderStatus,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return this.findOrderPage(
      { sellerId, ...(status ? { status } : {}) },
      page,
    );
  }

  async findSellerSales(
    sellerId: string,
    page: PageQuery,
    status: SalesOrderStatus | undefined,
    cursor: SalesOrderCursor | null,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return repositoryResponse(async () => {
      const where: Prisma.OrderWhereInput = {
        sellerId,
        ...(status ? { status } : {}),
        ...(cursor
          ? {
              OR: [
                { createdAt: { lt: cursor.createdAt } },
                { createdAt: cursor.createdAt, id: { lt: cursor.id } },
              ],
            }
          : {}),
      };
      const rows = await this.prisma.order.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        take: page.limit + 1,
        include: ORDER_INCLUDE_PRODUCT,
      });
      const hasMore = rows.length > page.limit;
      const items = hasMore ? rows.slice(0, page.limit) : rows;
      const last = items[items.length - 1];
      return {
        items,
        hasMore,
        nextCursor:
          hasMore && last
            ? encodeCursor({
                scope: "seller-sales",
                sellerId,
                status: status ?? "ALL",
                createdAt: last.createdAt.toISOString(),
                id: last.id,
              })
            : null,
      };
    }, "Erro ao buscar pedidos");
  }

  async countBySellerId(sellerId: string): RepositoryResponse<number> {
    return repositoryResponse(
      () => this.prisma.order.count({ where: { sellerId } }),
      "Erro ao contar pedidos",
    );
  }

  async countByBuyerId(buyerId: string): RepositoryResponse<number> {
    return repositoryResponse(
      () => this.prisma.order.count({ where: { buyerId } }),
      "Erro ao contar pedidos",
    );
  }

  private async findOrderPage(
    where: Prisma.OrderWhereInput,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<OrderProductPayload>> {
    return repositoryResponse(
      async () => {
        const rows = await this.prisma.order.findMany({
          where,
          orderBy: [{ createdAt: "desc" }, { id: "desc" }],
          take: page.limit + 1,
          ...(page.cursor ? { cursor: { id: page.cursor }, skip: 1 } : {}),
          include: ORDER_INCLUDE_PRODUCT,
        });
        return buildIdCursorPage(rows, page.limit);
      },
      "Erro ao buscar pedidos",
    );
  }
}
