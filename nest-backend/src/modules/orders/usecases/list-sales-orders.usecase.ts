import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { Injectable } from '@nestjs/common';
import { Either, left } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { clampLimit } from '@/shared/core/pagination';
import {
  SALES_ORDER_STATUSES,
  SalesOrderCursor,
  SalesOrderStatus,
} from '../types/order.types';
import { SalesOrdersQueryDTO } from '../dtos/order.dto';
import { CursorPage } from '@/shared/core/pagination';
import { OrderProductPayload } from '../types/order.types';

@Injectable()
export class ListSalesOrdersUseCase {
  constructor(private readonly orderRepository: PrismaOrderRepository) {}

  async execute(
    userId: string,
    query: SalesOrdersQueryDTO,
  ): Promise<Either<AppError, CursorPage<OrderProductPayload>>> {
    const status = query.status;
    if (status && !this.isSalesOrderStatus(status)) {
      return left(new BadRequestError('Status de pedido inválido'));
    }

    const cursor = this.decodeSalesCursor(query.cursor);
    if (query.cursor && !cursor) {
      return left(new BadRequestError('Cursor de vendas inválido'));
    }
    if (
      cursor &&
      (cursor.sellerId !== userId || cursor.status !== (status ?? null))
    ) {
      return left(new BadRequestError('Cursor de vendas inválido'));
    }

    return this.orderRepository.findSellerSales(
      userId,
      { limit: clampLimit(query.limit) },
      status,
      cursor,
    );
  }

  private isSalesOrderStatus(status: string): status is SalesOrderStatus {
    return SALES_ORDER_STATUSES.some((candidate) => candidate === status);
  }

  private decodeSalesCursor(raw?: string): SalesOrderCursor | null {
    if (!raw) return null;
    try {
      const decoded: unknown = JSON.parse(
        Buffer.from(raw, 'base64url').toString('utf8'),
      );
      if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
        return null;
      }

      if (!this.isRecord(decoded)) return null;
      const value = decoded;
      const keys = Object.keys(value).sort().join(',');
      if (keys !== 'createdAt,id,scope,sellerId,status') return null;
      if (value.scope !== 'seller-sales') return null;
      if (typeof value.sellerId !== 'string' || !value.sellerId) return null;
      if (typeof value.id !== 'string' || !value.id) return null;
      if (typeof value.createdAt !== 'string') return null;

      const createdAt = new Date(value.createdAt);
      if (Number.isNaN(createdAt.getTime())) return null;

      const status = value.status === 'ALL' ? null : value.status;
      if (
        status !== null &&
        (typeof status !== 'string' || !this.isSalesOrderStatus(status))
      ) {
        return null;
      }

      return {
        scope: 'seller-sales',
        sellerId: value.sellerId,
        status,
        createdAt,
        id: value.id,
      };
    } catch {
      return null;
    }
  }

  private isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
  }
}
