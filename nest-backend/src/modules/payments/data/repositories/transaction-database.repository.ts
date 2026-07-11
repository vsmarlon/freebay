import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { left, right, RepositoryResponse } from '@/shared/core/either';
import { DatabaseError, Failure } from '@/shared/core/errors';
import { TransactionRepository, TransactionWithOrder } from '../../domain/repositories/transaction.repository';

@Injectable()
export class TransactionDatabaseRepository implements TransactionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async markAsPaid(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    try {
      const client = tx ?? this.prisma;
      await client.transaction.update({
        where: { id },
        data: { status: 'PAID', paidAt: new Date() },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to mark transaction as paid'));
    }
  }

  async markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    try {
      const client = tx ?? this.prisma;
      await client.transaction.update({
        where: { id },
        data: { status: 'FAILED' },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to mark transaction as failed'));
    }
  }

  async findByIdempotencyKey(key: string): Promise<import('@/shared/core/either').Either<Failure, TransactionWithOrder | null>> {
    try {
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
      return right(transaction as TransactionWithOrder | null);
    } catch {
      return left(new DatabaseError('Failed to find transaction'));
    }
  }
}
