import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput } from '../dtos/dispute.dto';

@Injectable()
export class GetDisputeUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(disputeId: string, userId: string): Promise<Either<AppError, GetDisputeOutput>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
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
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isParticipant = dispute.order.buyerId === userId || dispute.order.sellerId === userId;
    if (!isParticipant) {
      return left(new UnauthorizedError('Not authorized to view this dispute'));
    }

    return right(dispute);
  }
}
