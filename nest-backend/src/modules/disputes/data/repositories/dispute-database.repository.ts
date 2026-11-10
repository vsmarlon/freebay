import { Injectable } from '@nestjs/common';
import { Dispute, DisputeStatus, EscrowStatus, OrderStatus, Prisma } from '@prisma/client';
import { Transactional, TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeWithOrder, CreateDisputeInput } from '../../types/dispute.types';

@Injectable()
export class DisputeDatabaseRepository {
  constructor(private readonly txHost: TransactionHost<TransactionalAdapterPrisma>) {
  }

  async create(data: CreateDisputeInput, tx?: Prisma.TransactionClient): RepositoryResponse<Dispute> {
    return repositoryResponse(() => (tx ?? this.txHost.tx).dispute.create({
      data: {
        order: { connect: { id: data.orderId } },
        openedBy: { connect: { id: data.openedById } },
        reason: data.reason,
        status: DisputeStatus.OPEN,
        expiresAt: data.expiresAt,
      },
    }), 'Failed to create dispute');
  }

  async findById(id: string): RepositoryResponse<DisputeWithOrder | null> {
    return repositoryResponse(() => this.txHost.tx.dispute.findUnique({
      where: { id },
      include: { order: true },
    }), 'Failed to find dispute');
  }

  async findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null> {
    return repositoryResponse(() => this.txHost.tx.dispute.findUnique({
      where: { id },
      include: {
        order: {
          include: {
            buyer: { select: USER_SELECT_MINIMAL },
            seller: { select: USER_SELECT_MINIMAL },
            product: true,
          },
        },
        openedBy: { select: { id: true, displayName: true } },
      },
    }), 'Failed to find dispute details');
  }

  async findByUserId(userId: string): RepositoryResponse<GetUserDisputesOutput> {
    return repositoryResponse(() => this.txHost.tx.dispute.findMany({
      where: {
        order: {
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
      },
      include: {
        order: {
          include: { product: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    }), 'Failed to find user disputes');
  }

  async update(id: string, data: Prisma.DisputeUpdateInput): RepositoryResponse<Dispute> {
    return repositoryResponse(() => this.txHost.tx.dispute.update({ where: { id }, data }), 'Failed to update dispute');
  }

  /**
   * Withdraw path: cast the dispute and restore the order in one transaction.
   * Same two queries in the same order the use case executed inline.
   */
  @Transactional()
  async executeWithdrawal(disputeId: string, orderId: string): Promise<void> {
    await this.txHost.tx.dispute.update({
      where: { id: disputeId },
      data: { status: DisputeStatus.CANCELLED, resolvedAt: new Date() },
    });

    await this.txHost.tx.order.update({
      where: { id: orderId },
      data: { status: OrderStatus.DELIVERED, escrowStatus: EscrowStatus.HELD },
    });
  }

  /**
   * Optimistic claim of the order for a buyer refund. Root statement
   * executed outside any transaction, as before.
   */
  async claimOrderForBuyerRefund(orderId: string, refundPendingReason: string): Promise<{ count: number }> {
    return this.txHost.tx.order.updateMany({
      where: {
        id: orderId,
        status: OrderStatus.DISPUTED,
        escrowStatus: EscrowStatus.HELD,
        OR: [{ cancellationReason: null }, { cancellationReason: refundPendingReason }],
      },
      data: { cancellationReason: refundPendingReason },
    });
  }
}
