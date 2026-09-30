import { Prisma } from "@prisma/client";
import { Injectable } from "@nestjs/common";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse, left, right } from "@/shared/core/either";
import { BadRequestError, DatabaseError, ForbiddenError } from "@/shared/core/errors";
import { UserBrief } from "../../types/user.types";
import { FollowRepository } from '../../domain/repositories/follow.repository';

@Injectable()
export class PrismaFollowRepository extends FollowRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async follow(
    followerId: string,
    followingId: string,
  ): RepositoryResponse<void> {
    try {
      const blocked = await this.prisma.block.findFirst({
        where: { OR: [
          { blockerId: followerId, blockedId: followingId },
          { blockerId: followingId, blockedId: followerId },
        ] }, select: { id: true },
      });
      if (blocked) return left(new ForbiddenError('Não é possível seguir um usuário bloqueado'));
      await this.prisma.follow.create({ data: { followerId, followingId } });
      return right(undefined);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      )
        return left(new BadRequestError("Already following"));
      return left(new DatabaseError("Failed to follow user"));
    }
  }

  async unfollow(
    followerId: string,
    followingId: string,
  ): RepositoryResponse<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.follow.delete({ where: { followerId_followingId: { followerId, followingId } } });
        const remainingConnection = await tx.follow.findFirst({ where: { OR: [
          { followerId, followingId }, { followerId: followingId, followingId: followerId },
        ] }, select: { id: true } });
        if (!remainingConnection) {
          await tx.closeFriend.deleteMany({ where: { OR: [
            { ownerId: followingId, memberId: followerId },
            { ownerId: followerId, memberId: followingId },
          ] } });
        }
      });
      return right(undefined);
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2025"
      )
        return left(new BadRequestError("Not following"));
      return left(new DatabaseError("Failed to unfollow user"));
    }
  }

  async isFollowing(
    followerId: string,
    followingId: string,
  ): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const follow = await this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId, followingId } },
      });
      return !!follow;
    }, "Failed to check follow status");
  }

  async getFollowers(
    userId: string,
    limit: number,
    offset: number,
  ): RepositoryResponse<UserBrief[]> {
    return repositoryResponse(
      () =>
        this.prisma.user.findMany({
          where: { following: { some: { followingId: userId } } },
          orderBy: [{ displayName: "asc" }, { id: "asc" }],
          take: limit,
          skip: offset,
          select: {
            id: true,
            displayName: true,
            username: true,
            avatarUrl: true,
            isVerified: true,
            reputationScore: true,
          },
        }),
      "Failed to get followers",
    );
  }

  async getFollowing(
    userId: string,
    limit: number,
    offset: number,
  ): RepositoryResponse<UserBrief[]> {
    return repositoryResponse(
      () =>
        this.prisma.user.findMany({
          where: { followers: { some: { followerId: userId } } },
          orderBy: [{ displayName: "asc" }, { id: "asc" }],
          take: limit,
          skip: offset,
          select: {
            id: true,
            displayName: true,
            username: true,
            avatarUrl: true,
            isVerified: true,
            reputationScore: true,
          },
        }),
      "Failed to get following",
    );
  }

  async getFollowersCount(userId: string): RepositoryResponse<number> {
    return repositoryResponse(
      () => this.prisma.follow.count({ where: { followingId: userId } }),
      "Failed to get followers count",
    );
  }

  async getFollowingCount(userId: string): RepositoryResponse<number> {
    return repositoryResponse(
      () => this.prisma.follow.count({ where: { followerId: userId } }),
      "Failed to get following count",
    );
  }
}
