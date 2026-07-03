import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '@/modules/orders/repositories/order.repository';
import { FollowRepository } from '../repositories/follow.repository';
import { UserStatsResponse } from '../mappers/user.mapper';
import { GetUserStatsInput } from '../dtos/user.dto';

@Injectable()
export class GetUserStatsUseCase {
  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly followRepository: FollowRepository,
  ) {}

  async execute(input: GetUserStatsInput): Promise<Either<AppError, UserStatsResponse>> {
    const [salesCountResult, purchasesCountResult] = await Promise.all([
      this.orderRepository.countBySellerId(input.userId),
      this.orderRepository.countByBuyerId(input.userId),
    ]);

    if (isLeft(salesCountResult)) return left(salesCountResult.value);
    if (isLeft(purchasesCountResult)) return left(purchasesCountResult.value);

    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.getFollowersCount(input.userId),
      this.followRepository.getFollowingCount(input.userId),
    ]);

    return right({
      salesCount: salesCountResult.value,
      purchasesCount: purchasesCountResult.value,
      followersCount,
      followingCount,
    });
  }
}
