import { EscrowStatus, OrderStatus, Prisma, Product, ProductStatus } from "@prisma/client";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { RepositoryResponse, left, right } from "@/shared/core/either";
import { BadRequestError, DatabaseError, NotFoundError } from "@/shared/core/errors";
import {
  CreateOrderPayload,
  CreateOrderTxData,
  ORDER_SELECT_CREATE,
} from "../../types/order.types";

export class OrderReservationRepository {
  constructor(private readonly prisma: PrismaService) {}
  async createOrderWithReservation(
    data: CreateOrderTxData,
  ): RepositoryResponse<CreateOrderPayload> {
    const PRODUCT_NOT_FOUND = "PRODUCT_NOT_FOUND";
    const OUT_OF_STOCK = "OUT_OF_STOCK";
    const PRODUCT_UNAVAILABLE = "PRODUCT_UNAVAILABLE";
    const OWN_PRODUCT = "OWN_PRODUCT";

    try {
      const order = await this.prisma.$transaction(async (tx) => {
        const products = await tx.$queryRaw<Product[]>`
          SELECT * FROM "Product" WHERE id = ${data.productId} FOR UPDATE
        `;
        const current = products[0];
        if (!current) throw new Error(PRODUCT_NOT_FOUND);
        if (current.sellerId === data.buyerId) throw new Error(OWN_PRODUCT);
        if (current.status !== ProductStatus.ACTIVE) throw new Error(PRODUCT_UNAVAILABLE);

        const amount = current.price;
        const platformFee = Math.round(
          amount * ((data.platformFeePercent ?? 10) / 100),
        );
        const sellerAmount = amount - platformFee;

        if (current.quantity > 1) {
          if (current.quantity <= current.soldCount) throw new Error(OUT_OF_STOCK);
          const newSoldCount = current.soldCount + 1;
          await tx.product.update({
            where: { id: data.productId },
            data: {
              soldCount: newSoldCount,
              ...(newSoldCount >= current.quantity ? { status: ProductStatus.SOLD } : {}),
            },
          });
        } else {
          const reserveResult = await tx.product.updateMany({
            where: { id: data.productId, status: ProductStatus.ACTIVE },
            data: { status: ProductStatus.PAUSED },
          });
          if (reserveResult.count === 0) throw new Error(PRODUCT_UNAVAILABLE);
        }

        const created = await tx.order.create({
          data: {
            buyer: { connect: { id: data.buyerId } },
            seller: { connect: { id: current.sellerId } },
            product: { connect: { id: data.productId } },
            amount,
            platformFee,
            sellerAmount,
            status: OrderStatus.PENDING,
            escrowStatus: EscrowStatus.HELD,
          },
          select: ORDER_SELECT_CREATE,
        });

        await tx.chatMessage.create({
          data: {
            orderId: created.id,
            senderId: data.buyerId,
            content: "Pedido criado! Aproveite para combinar os detalhes da entrega.",
          },
        });
        return created;
      });
      return right(order);
    } catch (e) {
      if (e instanceof Error) {
        if (e.message === PRODUCT_NOT_FOUND) return left(new NotFoundError("Produto"));
        if (e.message === OWN_PRODUCT) return left(new BadRequestError("Cannot buy your own product"));
        if (e.message === OUT_OF_STOCK) return left(new BadRequestError("Produto sem estoque"));
        if (e.message === PRODUCT_UNAVAILABLE) return left(new BadRequestError("Produto não está mais disponível"));
      }
      return left(new DatabaseError("Erro ao criar pedido"));
    }
  }

  async restoreProductInventory(
    tx: Prisma.TransactionClient,
    productId: string,
    orderQuantity: number,
  ): Promise<void> {
    const product = await tx.product.findUnique({
      where: { id: productId },
      select: { quantity: true },
    });
    if ((product?.quantity ?? 1) > 1) {
      await tx.product.updateMany({
        where: { id: productId, soldCount: { gte: orderQuantity } },
        data: { soldCount: { decrement: orderQuantity } },
      });
      await tx.product.updateMany({
        where: { id: productId, status: ProductStatus.SOLD },
        data: { status: ProductStatus.ACTIVE },
      });
      return;
    }
    await tx.product.update({
      where: { id: productId },
      data: { status: ProductStatus.ACTIVE },
    });
  }
}
