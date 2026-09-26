import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FollowRepository } from '../domain/repositories/follow.repository';
import { UserLookupRepository } from '../domain/repositories/user-lookup.repository';
import { NotFoundError } from '@/shared/core/errors';
import { toUserBrief } from '../mappers/user.mapper';

export type ListFollowersInput = { userId: string; limit: number; offset: number; verifyUser?: boolean };

@Injectable()
export class ListFollowersUseCase {
  constructor(
    private readonly followRepository: FollowRepository,
    private readonly userRepository: UserLookupRepository,
  ) {}

  async execute(input: ListFollowersInput): Promise<Either<AppError, { users: ReturnType<typeof toUserBrief>[]; total: number; limit: number; offset: number }>> {
    if (input.verifyUser) {
      const profileResult = await this.userRepository.findById(input.userId);
      if (profileResult.isLeft()) return left(profileResult.value);
      if (!profileResult.value) return left(new NotFoundError('Usuário'));
    }
    const [usersResult, totalResult] = await Promise.all([
      this.followRepository.getFollowers(input.userId, input.limit, input.offset),
      this.followRepository.getFollowersCount(input.userId),
    ]);
    if (usersResult.isLeft()) return left(usersResult.value);
    if (totalResult.isLeft()) return left(totalResult.value);
    return right({ users: usersResult.value.map(toUserBrief), total: totalResult.value, limit: input.limit, offset: input.offset });
  }
}
