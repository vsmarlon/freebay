import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { FollowRepository } from '../domain/repositories/follow.repository';
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

    if (salesCountResult.isLeft()) return left(salesCountResult.value);
    if (purchasesCountResult.isLeft()) return left(purchasesCountResult.value);

    const [followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.getFollowersCount(input.userId),
      this.followRepository.getFollowingCount(input.userId),
    ]);

    if (followersCountResult.isLeft()) return left(followersCountResult.value);
    if (followingCountResult.isLeft()) return left(followingCountResult.value);

    return right({
      salesCount: salesCountResult.value,
      purchasesCount: purchasesCountResult.value,
      followersCount: followersCountResult.value,
      followingCount: followingCountResult.value,
    });
  }
}
