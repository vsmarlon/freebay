import {
  Controller,
  Body,
  Param,
  Query,
  HttpStatus,
  ParseUUIDPipe,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  CurrentUser,
  CurrentUserId,
  Paginated,
  PAGINATION_QUERIES,
} from "@/shared/decorators";
import { clampLimit, PageQuery } from "@/shared/core/pagination";
import { PrismaOrderRepository } from "./data/repositories/order-database.repository";
import { OrderStatus } from "@prisma/client";
import { CreateOrderUseCase } from "./usecases/create-order.usecase";
import { ConfirmDeliveryUseCase } from "./usecases/confirm-delivery.usecase";
import { MarkAsShippedUseCase } from "./usecases/mark-as-shipped.usecase";
import { MarkAsDeliveredUseCase } from "./usecases/mark-as-delivered.usecase";
import { CancelOrderUseCase } from "./usecases/cancel-order.usecase";
import { CreateOrderDTO, SalesOrdersQueryDTO } from "./dtos/order.dto";
import {
  SALES_ORDER_STATUSES,
  SalesOrderCursor,
  SalesOrderStatus,
} from "./types/order.types";
import { AuthUser } from "@/shared/core/types";
import { left } from "@/shared/core/either";
import {
  NotFoundError,
  ForbiddenError,
  BadRequestError,
} from "@/shared/core/errors";
import { getPlatformFeePercent } from "@/shared/core/platform-fee";

@ApiTags("Orders")
@Controller("orders")
export class OrdersController {
  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly createOrderUseCase: CreateOrderUseCase,
    private readonly confirmDeliveryUseCase: ConfirmDeliveryUseCase,
    private readonly markAsShippedUseCase: MarkAsShippedUseCase,
    private readonly markAsDeliveredUseCase: MarkAsDeliveredUseCase,
    private readonly cancelOrderUseCase: CancelOrderUseCase,
  ) {}

  @PostAuth({
    summary: "Create order",
    bodyType: CreateOrderDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
    errors: [{ status: 404, description: "Product not found" }],
  })
  async create(@CurrentUserId() buyerId: string, @Body() body: CreateOrderDTO) {
    return this.createOrderUseCase.execute({
      buyerId,
      productId: body.productId,
      platformFeePercent: getPlatformFeePercent(),
    });
  }

  @GetAuth("my/purchases", {
    summary: "Get my purchases",
    queries: PAGINATION_QUERIES,
  })
  async getMyPurchases(
    @CurrentUserId() userId: string,
    @Paginated() page: PageQuery,
    @Query("status") status?: string,
  ) {
    const parsedStatus = this.parseStatus(status);
    if (status && !parsedStatus)
      return left(new BadRequestError("Status de pedido inválido"));
    return this.orderRepository.findByBuyerId(userId, page, parsedStatus);
  }

  @GetAuth("my/sales", { summary: "Get my sales", queries: PAGINATION_QUERIES })
  async getMySales(
    @CurrentUserId() userId: string,
    @Query() query: SalesOrdersQueryDTO,
  ) {
    const parsedStatus = query.status;
    if (query.status && !this.isSalesOrderStatus(query.status))
      return left(new BadRequestError("Status de pedido inválido"));
    const cursor = this.decodeSalesCursor(query.cursor);
    if (query.cursor && !cursor)
      return left(new BadRequestError("Cursor de vendas inválido"));
    if (
      cursor &&
      (cursor.sellerId !== userId || cursor.status !== (parsedStatus ?? null))
    ) {
      return left(new BadRequestError("Cursor de vendas inválido"));
    }
    return this.orderRepository.findSellerSales(
      userId,
      { limit: clampLimit(query.limit) },
      parsedStatus,
      cursor,
    );
  }

  @GetAuth(":id", {
    summary: "Get order by ID",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [
      { status: 404, description: "Order not found" },
      { status: 403, description: "Access denied" },
    ],
  })
  async findOne(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthUser,
  ) {
    const result = await this.orderRepository.findById(id);
    if (result.isLeft()) return result;
    if (!result.value) return left(new NotFoundError("Pedido"));

    const order = result.value;
    if (
      order.buyerId !== user.userId &&
      order.sellerId !== user.userId &&
      user.role !== "ADMIN"
    ) {
      return left(
        new ForbiddenError(
          "Você não tem permissão para visualizar este pedido",
        ),
      );
    }

    return { order };
  }

  @PatchAuth(":id/ship", {
    summary: "Mark order as shipped",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [{ status: 404, description: "Order not found" }],
  })
  async markAsShipped(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() sellerId: string,
  ) {
    return this.markAsShippedUseCase.execute({ orderId: id, sellerId });
  }

  @PatchAuth(":id/deliver", {
    summary: "Mark order as delivered",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [{ status: 404, description: "Order not found" }],
  })
  async markAsDelivered(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() buyerId: string,
  ) {
    return this.markAsDeliveredUseCase.execute({ orderId: id, buyerId });
  }

  @PatchAuth(":id/confirm", {
    summary: "Confirm delivery (release escrow to seller)",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [{ status: 404, description: "Order not found" }],
  })
  async confirmDelivery(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() buyerId: string,
  ) {
    return this.confirmDeliveryUseCase.execute({ orderId: id, buyerId });
  }

  @PatchAuth(":id/confirm-delivery", {
    summary: "Confirm delivery (alias)",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [{ status: 404, description: "Order not found" }],
  })
  async confirmDeliveryAlias(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() buyerId: string,
  ) {
    return this.confirmDelivery(id, buyerId);
  }

  @PatchAuth(":id/cancel", {
    summary: "Cancel order",
    params: [{ name: "id", description: "Order UUID" }],
    errors: [{ status: 404, description: "Order not found" }],
  })
  async cancel(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.cancelOrderUseCase.execute({ orderId: id, userId });
  }

  @GetAuth({
    summary: "List user orders",
    queries: [
      {
        name: "role",
        required: false,
        description: 'Filter by role: "seller" or "buyer" (default)',
      },
      ...PAGINATION_QUERIES,
    ],
  })
  async findAll(
    @CurrentUserId() userId: string,
    @Paginated() page: PageQuery,
    @Query("role") role?: string,
    @Query("status") status?: string,
  ) {
    const parsedStatus = this.parseStatus(status);
    if (status && !parsedStatus)
      return left(new BadRequestError("Status de pedido inválido"));
    return role === "seller"
      ? this.orderRepository.findBySellerId(userId, page, parsedStatus)
      : this.orderRepository.findByBuyerId(userId, page, parsedStatus);
  }

  private parseStatus(status?: string): OrderStatus | undefined {
    return status && Object.values(OrderStatus).includes(status as OrderStatus)
      ? (status as OrderStatus)
      : undefined;
  }

  private isSalesOrderStatus(status: string): status is SalesOrderStatus {
    return (SALES_ORDER_STATUSES as readonly string[]).includes(status);
  }

  private decodeSalesCursor(raw?: string): SalesOrderCursor | null {
    if (!raw) return null;
    try {
      const decoded: unknown = JSON.parse(
        Buffer.from(raw, "base64url").toString("utf8"),
      );
      if (!decoded || typeof decoded !== "object" || Array.isArray(decoded))
        return null;
      const value = decoded as Record<string, unknown>;
      const keys = Object.keys(value).sort().join(",");
      if (keys !== "createdAt,id,scope,sellerId,status") return null;
      if (value.scope !== "seller-sales") return null;
      if (typeof value.sellerId !== "string" || !value.sellerId) return null;
      if (typeof value.id !== "string" || !value.id) return null;
      if (typeof value.createdAt !== "string") return null;
      const createdAt = new Date(value.createdAt);
      if (Number.isNaN(createdAt.getTime())) return null;
      const status = value.status === "ALL" ? null : value.status;
      if (status !== null &&
          (typeof status !== "string" || !this.isSalesOrderStatus(status)))
        return null;
      return {
        scope: "seller-sales",
        sellerId: value.sellerId,
        status,
        createdAt,
        id: value.id,
      };
    } catch {
      return null;
    }
  }
}
