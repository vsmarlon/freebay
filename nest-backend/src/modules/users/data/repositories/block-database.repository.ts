import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { BlockRepository } from '../../domain/repositories/block.repository';
import { UserBrief } from '../../domain/repositories/follow.repository';

@Injectable()
export class PrismaBlockRepository implements BlockRepository {
  constructor(private readonly prisma: PrismaService) {}

  async block(blockerId: string, blockedId: string): RepositoryResponse<void> {
    try {
      await this.prisma.block.create({ data: { blockerId, blockedId } });
      return right(undefined);
    } catch (error: any) {
      if (error?.code === 'P2002') {
        return left(new BadRequestError('Already blocked'));
      }
      return left(new DatabaseError('Failed to block user'));
    }
  }

  async unblock(blockerId: string, blockedId: string): RepositoryResponse<void> {
    try {
      await this.prisma.block.delete({
        where: { blockerId_blockedId: { blockerId, blockedId } },
      });
      return right(undefined);
    } catch (error: any) {
      if (error?.code === 'P2025') {
        return left(new BadRequestError('Not blocked'));
      }
      return left(new DatabaseError('Failed to unblock user'));
    }
  }

  async isBlocked(blockerId: string, blockedId: string): RepositoryResponse<boolean> {
    try {
      const block = await this.prisma.block.findUnique({
        where: { blockerId_blockedId: { blockerId, blockedId } },
      });
      return right(!!block);
    } catch {
      return left(new DatabaseError('Failed to check block status'));
    }
  }

  async getBlockedUsers(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]> {
    try {
      return right(
        await this.prisma.user.findMany({
          where: { blocksGiven: { some: { blockerId: userId } } },
          take: limit,
          skip: offset,
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isVerified: true,
            reputationScore: true,
          },
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to get blocked users'));
    }
  }
}
