import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { FollowRepository } from '../repositories/follow.repository';
import { FollowResponse } from '../mappers/user.mapper';
import { FollowUserInput } from '../dtos/user.dto';

@Injectable()
export class UnfollowUserUseCase {
  constructor(
    private readonly followRepository: FollowRepository,
  ) {}

  async execute(input: FollowUserInput): Promise<Either<AppError, FollowResponse>> {
    try {
      await this.followRepository.unfollow(input.followerId, input.followingId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new BadRequestError('Not following'));
      }
      return left(new AppError('DB_ERROR', 'Erro ao deixar de seguir usuário'));
    }

    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);

    return right({ following: false, followersCount, followingCount });
  }
}
