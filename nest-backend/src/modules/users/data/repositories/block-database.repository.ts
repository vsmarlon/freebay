import { Prisma } from '@prisma/client';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { UserBrief } from '../../types/user.types';
import { BlockRepository } from '../../domain/repositories/block.repository';

@Injectable()
export class PrismaBlockRepository extends BlockRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async block(blockerId: string, blockedId: string): RepositoryResponse<void> {
    try {
      await this.prisma.block.create({ data: { blockerId, blockedId } });
      return right(undefined);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') return left(new BadRequestError('Already blocked'));
      return left(new DatabaseError('Failed to block user'));
    }
  }

  async unblock(blockerId: string, blockedId: string): RepositoryResponse<void> {
    try {
      await this.prisma.block.delete({ where: { blockerId_blockedId: { blockerId, blockedId } } });
      return right(undefined);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') return left(new BadRequestError('Not blocked'));
      return left(new DatabaseError('Failed to unblock user'));
    }
  }

  async isBlocked(blockerId: string, blockedId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const block = await this.prisma.block.findUnique({ where: { blockerId_blockedId: { blockerId, blockedId } } });
      return !!block;
    }, 'Failed to check block status');
  }

  async getBlockedUsers(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]> {
    return repositoryResponse(() => this.prisma.user.findMany({
      where: { blocksGiven: { some: { blockerId: userId } } },
      take: limit,
      skip: offset,
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true, reputationScore: true },
    }), 'Failed to get blocked users');
  }
}
