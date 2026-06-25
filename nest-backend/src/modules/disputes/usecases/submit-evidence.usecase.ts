import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class SubmitEvidenceUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: { disputeId: string; userId: string; evidence: Prisma.InputJsonValue }): Promise<Either<AppError, { submitted: boolean }>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: input.disputeId },
      include: { order: true },
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isBuyer = dispute.order.buyerId === input.userId;
    const isSeller = dispute.order.sellerId === input.userId;
    if (!isBuyer && !isSeller) {
      return left(new UnauthorizedError('Not authorized'));
    }

    const updateData = isBuyer
      ? { buyerEvidence: input.evidence, status: 'AWAITING_SELLER' as const }
      : { sellerEvidence: input.evidence, status: 'AWAITING_BUYER' as const };

    await this.prisma.dispute.update({
      where: { id: input.disputeId },
      data: updateData,
    });

    return right({ submitted: true });
  }
}
