import { Injectable } from '@nestjs/common';
import { Dispute, DisputeStatus, EscrowStatus, OrderStatus, Prisma, CancellationKind } from '@prisma/client';
import { Transactional, TransactionHost } from '@nestjs-cls/transactional';
import { TransactionalAdapterPrisma } from '@nestjs-cls/transactional-adapter-prisma';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse, right } from '@/shared/core/either';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeWithOrder, CreateDisputeInput } from '../../types/dispute.types';
import {
  DisputeParty,
  ESCALATABLE_DISPUTE_STATUSES,
  evidenceTarget,
} from '../../domain/dispute-state';

const DISPUTE_DETAILS_INCLUDE = {
  order: {
    include: {
      buyer: { select: USER_SELECT_MINIMAL },
      seller: { select: USER_SELECT_MINIMAL },
      product: true,
    },
  },
  openedBy: { select: { id: true, displayName: true } },
} satisfies Prisma.DisputeInclude;

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
      include: DISPUTE_DETAILS_INCLUDE,
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

  async findAdminQueue(status?: DisputeStatus, limit = 100): RepositoryResponse<GetDisputeOutput[]> {
    return repositoryResponse(() => this.txHost.tx.dispute.findMany({
      where: status ? { status } : undefined,
      include: DISPUTE_DETAILS_INCLUDE,
      orderBy: [{ createdAt: 'asc' }],
      take: limit,
    }), 'Failed to list disputes for moderation');
  }

  /**
   * Guarded evidence submission: the expected status is part of the predicate,
   * so a concurrent resolve or escalation cannot be overwritten. The awaited
   * party is the only one allowed to submit, and each submission flips it.
   */
  async submitEvidence(params: {
    disputeId: string;
    expectedStatus: DisputeStatus;
    party: DisputeParty;
    evidence: Prisma.InputJsonValue;
  }): RepositoryResponse<boolean> {
    const target = evidenceTarget(params.expectedStatus, params.party);
    if (target === null) return right(false);
    const data: Prisma.DisputeUpdateManyMutationInput = params.party === 'BUYER'
      ? { buyerEvidence: params.evidence, status: target }
      : { sellerEvidence: params.evidence, status: target };

    return repositoryResponse(async () => {
      const claimed = await this.txHost.tx.dispute.updateMany({
        where: { id: params.disputeId, status: params.expectedStatus },
        data,
      });
      return claimed.count > 0;
    }, 'Failed to submit dispute evidence');
  }

  /**
   * Withdraw path: cast the dispute and restore the pre-dispute order state in
   * one transaction. Both writes are guarded; a lost claim throws so the
   * transaction rolls back instead of leaving a cancelled dispute behind.
   */
  @Transactional()
  async withdraw(params: {
    disputeId: string;
    orderId: string;
    expectedStatus: DisputeStatus;
  }): Promise<boolean> {
    const claimed = await this.txHost.tx.dispute.updateMany({
      where: { id: params.disputeId, status: params.expectedStatus },
      data: { status: DisputeStatus.CANCELLED, resolvedAt: new Date() },
    });
    if (claimed.count === 0) return false;

    const order = await this.txHost.tx.order.findUnique({
      where: { id: params.orderId },
      select: { status: true, preDisputeStatus: true },
    });
    if (!order || order.status !== OrderStatus.DISPUTED) {
      throw new Error('DISPUTE_WITHDRAW_ORDER_NOT_DISPUTED');
    }

    const restored = await this.txHost.tx.order.updateMany({
      where: { id: params.orderId, status: OrderStatus.DISPUTED },
      data: {
        // Legacy rows predate preDisputeStatus; DELIVERED is their pre-dispute state.
        status: order.preDisputeStatus ?? OrderStatus.DELIVERED,
        escrowStatus: EscrowStatus.HELD,
        preDisputeStatus: null,
      },
    });
    if (restored.count === 0) throw new Error('DISPUTE_WITHDRAW_ORDER_CLAIM_LOST');
    return true;
  }

  /**
   * Reopen a withdrawn dispute in place. The order returns to DISPUTED and the
   * dispute to OPEN; the caller supplies the new escalation deadline.
   */
  @Transactional()
  async reopen(params: {
    disputeId: string;
    orderId: string;
    reason: string;
    expiresAt: Date;
  }): Promise<boolean> {
    const claimed = await this.txHost.tx.dispute.updateMany({
      where: { id: params.disputeId, status: DisputeStatus.CANCELLED },
      data: {
        status: DisputeStatus.OPEN,
        reason: params.reason,
        resolvedAt: null,
        expiresAt: params.expiresAt,
      },
    });
    if (claimed.count === 0) return false;

    const order = await this.txHost.tx.order.findUnique({
      where: { id: params.orderId },
      select: { status: true },
    });
    if (!order) throw new Error('DISPUTE_REOPEN_ORDER_NOT_FOUND');

    const moved = await this.txHost.tx.order.updateMany({
      where: { id: params.orderId, status: order.status },
      data: { status: OrderStatus.DISPUTED, preDisputeStatus: order.status },
    });
    if (moved.count === 0) throw new Error('DISPUTE_REOPEN_ORDER_CLAIM_LOST');
    return true;
  }

  /**
   * Move every active dispute whose escalation deadline passed to ESCALATED.
   * No money moves; the admin queue becomes the SLA.
   */
  async escalateExpired(now: Date): RepositoryResponse<number> {
    return repositoryResponse(async () => {
      const escalated = await this.txHost.tx.dispute.updateMany({
        where: {
          status: { in: [...ESCALATABLE_DISPUTE_STATUSES] },
          expiresAt: { lt: now },
        },
        data: { status: DisputeStatus.ESCALATED },
      });
      return escalated.count;
    }, 'Failed to escalate expired disputes');
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
      data: {
        cancellationReason: refundPendingReason,
        cancellationKind: CancellationKind.DISPUTE_REFUND,
      },
    });
  }
}
