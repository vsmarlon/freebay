import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetUserDisputesOutput } from '../dtos/dispute.dto';

@Injectable()
export class GetUserDisputesUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(userId: string): Promise<Either<AppError, GetUserDisputesOutput>> {
    const disputes = await this.prisma.dispute.findMany({
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
    });

    return right(disputes);
  }
}
