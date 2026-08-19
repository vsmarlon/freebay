import { Injectable } from '@nestjs/common';
import { Prisma, Transaction } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { TransactionRepository } from '../../domain/repositories/transaction.repository';
import { TransactionWithOrder, UpsertTransactionData } from '../../types/payment.types';

@Injectable()
export class TransactionDatabaseRepository extends BasePrismaRepository implements TransactionRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async markAsPaid(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      const result = await client.transaction.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'PAID', paidAt: new Date() },
      });
      return { count: result.count };
    }, 'Failed to mark transaction as paid');
  }

  async markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      const result = await client.transaction.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'FAILED' },
      });
      return { count: result.count };
    }, 'Failed to mark transaction as failed');
  }

  async findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.safeRun(async () => {
      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: key },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
      });
      return transaction as TransactionWithOrder | null;
    }, 'Failed to find transaction');
  }

  async findByOrderId(orderId: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.safeRun(async () => {
      const transaction = await this.prisma.transaction.findUnique({
        where: { orderId },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
      });
      return transaction as TransactionWithOrder | null;
    }, 'Failed to find transaction by order id');
  }

  async findByDerivedKey(key: string): RepositoryResponse<Transaction | null> {
    return this.safeRun(() => this.prisma.transaction.findFirst({
      where: { idempotencyKey: key },
    }), 'Failed to find transaction by key');
  }

  async upsertTransaction(data: UpsertTransactionData): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.transaction.upsert({
        where: { orderId: data.orderId },
        create: {
          order: { connect: { id: data.orderId } },
          externalId: data.externalId,
          amount: data.amount,
          platformFee: data.platformFee,
          sellerAmount: data.sellerAmount,
          paymentMethod: data.paymentMethod,
          provider: 'STRIPE',
          status: 'PENDING',
          idempotencyKey: data.idempotencyKey,
          checkoutUrl: data.checkoutUrl,
          checkoutExpiresAt: data.checkoutExpiresAt,
        },
        update: {
          externalId: data.externalId,
          status: 'PENDING',
          checkoutUrl: data.checkoutUrl ?? undefined,
          checkoutExpiresAt: data.checkoutExpiresAt ?? undefined,
        },
      });
    }, 'Failed to upsert transaction');
  }
}
