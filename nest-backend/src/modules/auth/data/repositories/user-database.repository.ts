import { Injectable } from '@nestjs/common';
import { Prisma, User, PrismaClient } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '../../domain/repositories/user.repository';
import { UserSearchResult, UserSuggestionResult } from '../../types/user-search.types';

@Injectable()
export class UserDatabaseRepository implements UserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async findByEmail(email: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { email } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async findByUsername(username: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { username } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async create(data: Prisma.UserCreateInput): RepositoryResponse<User> {
    try {
      return right(await this.prisma.user.create({ data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar usuário'));
    }
  }

  async update(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User> {
    try {
      return right(await this.prisma.user.update({ where: { id }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar usuário'));
    }
  }

  async searchUsers(query: string, limit: number, offset: number, viewerId?: string): RepositoryResponse<UserSearchResult[]> {
    try {
      const q = query.trim();
      const likeAll = `%${q}%`;
      const prefixLike = `${q}%`;

      const blockFilter = viewerId
        ? Prisma.sql`
            AND NOT EXISTS (SELECT 1 FROM "Block" b WHERE b."blockerId" = u.id AND b."blockedId" = ${viewerId})
            AND NOT EXISTS (SELECT 1 FROM "Block" b WHERE b."blockerId" = ${viewerId} AND b."blockedId" = u.id)
          `
        : Prisma.empty;

      const rows = await this.prisma.$queryRaw<
        Array<{
          id: string;
          displayName: string;
          username: string;
          avatarUrl: string | null;
          bio: string | null;
          isVerified: boolean;
          reputationScore: number;
          totalReviews: number;
          followersCount: bigint;
          followingCount: bigint;
        }>
      >(Prisma.sql`
        SELECT
          u.id, u."displayName", u.username, u."avatarUrl", u.bio, u."isVerified",
          u."reputationScore", u."totalReviews",
          (SELECT COUNT(*) FROM "Follow" f WHERE f."followingId" = u.id) AS "followersCount",
          (SELECT COUNT(*) FROM "Follow" f WHERE f."followerId" = u.id) AS "followingCount"
        FROM "User" u
        WHERE (u.username ILIKE ${likeAll} OR u."displayName" ILIKE ${likeAll})
        ${blockFilter}
        ORDER BY
          CASE
            WHEN lower(u.username) = lower(${q}) THEN 0
            WHEN u.username ILIKE ${prefixLike} THEN 1
            ELSE 2
          END,
          "followersCount" DESC,
          u.id ASC
        LIMIT ${limit} OFFSET ${offset}
      `);

      return right(
        rows.map((r) => ({
          id: r.id,
          displayName: r.displayName,
          username: r.username,
          avatarUrl: r.avatarUrl,
          bio: r.bio,
          isVerified: r.isVerified,
          reputationScore: r.reputationScore,
          totalReviews: r.totalReviews,
          followersCount: Number(r.followersCount),
          followingCount: Number(r.followingCount),
        })),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao pesquisar usuários'));
    }
  }

  async getSuggestions(userId: string, limit: number): RepositoryResponse<UserSuggestionResult[]> {
    try {
      const following = await this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { followingId: true },
      });
      const followingIds = following.map((f) => f.followingId);

      const notBlocked: Prisma.UserWhereInput = {
        blocksGiven: { none: { blockedId: userId } },
        blocksReceived: { none: { blockerId: userId } },
      };

      const baseSelect = {
        id: true,
        displayName: true,
        username: true,
        avatarUrl: true,
        bio: true,
        isVerified: true,
        reputationScore: true,
        totalReviews: true,
        _count: { select: { followers: true, following: true } },
      } as const;

      const suggestions = followingIds.length
        ? await this.prisma.user.findMany({
            where: {
              id: { not: userId },
              followers: { some: { followerId: { in: followingIds } } },
              NOT: { followers: { some: { followerId: userId } } },
              ...notBlocked,
            },
            take: limit * 3,
            select: {
              ...baseSelect,
              followers: {
                where: { followerId: { in: followingIds } },
                select: { followerId: true },
              },
            },
          })
        : [];

      const ranked = suggestions
        .map((u) => ({
          id: u.id,
          displayName: u.displayName,
          username: u.username,
          avatarUrl: u.avatarUrl,
          bio: u.bio,
          isVerified: u.isVerified,
          reputationScore: u.reputationScore,
          totalReviews: u.totalReviews,
          followersCount: u._count.followers,
          followingCount: u._count.following,
          mutualCount: u.followers.length,
        }))
        .sort((a, b) =>
          b.mutualCount !== a.mutualCount
            ? b.mutualCount - a.mutualCount
            : b.followersCount - a.followersCount,
        )
        .slice(0, limit);

      if (ranked.length >= limit) return right(ranked);

      const alreadySuggested = new Set(ranked.map((u) => u.id));
      const popular = await this.prisma.user.findMany({
        where: {
          id: { not: userId, notIn: [...alreadySuggested] },
          NOT: { followers: { some: { followerId: userId } } },
          ...notBlocked,
        },
        take: limit - ranked.length,
        orderBy: { followers: { _count: 'desc' } },
        select: baseSelect,
      });

      return right([
        ...ranked,
        ...popular.map((u) => ({
          id: u.id,
          displayName: u.displayName,
          username: u.username,
          avatarUrl: u.avatarUrl,
          bio: u.bio,
          isVerified: u.isVerified,
          reputationScore: u.reputationScore,
          totalReviews: u.totalReviews,
          followersCount: u._count.followers,
          followingCount: u._count.following,
          mutualCount: 0,
        })),
      ]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar sugestões'));
    }
  }

  async findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { displayName: true, email: true, cpf: true },
      });
      return right(user);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar informações de pagamento'));
    }
  }
}
