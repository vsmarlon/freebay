import { Injectable } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '../../domain/repositories/user.repository';
import {
  UserProfileCounts,
  UserSearchResult,
  UserSuggestionResult,
  toUserSearchResult,
  toUserSuggestionResult,
} from '../../types/user.types';

/// Over-fetch mutual-follow candidates so the in-memory ranking has room to sort.
const SUGGESTION_CANDIDATE_MULTIPLIER = 3;

@Injectable()
export class UserDatabaseRepository implements UserRepository {
  constructor(private readonly prisma: PrismaService) {}

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

  async findByGoogleId(googleId: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { googleId } }));
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
        rows.map((r) =>
          toUserSearchResult(r, Number(r.followersCount), Number(r.followingCount)),
        ),
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
            take: limit * SUGGESTION_CANDIDATE_MULTIPLIER,
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
        .map((u) =>
          toUserSuggestionResult(
            u,
            u._count.followers,
            u._count.following,
            u.followers.length,
          ),
        )
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
        ...popular.map((u) =>
          toUserSuggestionResult(u, u._count.followers, u._count.following, 0),
        ),
      ]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar sugestões'));
    }
  }

  async getProfileCounts(userId: string): RepositoryResponse<UserProfileCounts> {
    try {
      const [postsCount, productsCount, activeStory] = await Promise.all([
        this.prisma.post.count({ where: { userId } }),
        this.prisma.product.count({ where: { sellerId: userId, status: { not: 'DELETED' } } }),
        this.prisma.story.findFirst({
          where: { userId, expiresAt: { gt: new Date() } },
          select: { id: true },
        }),
      ]);

      return right({ postsCount, productsCount, hasActiveStory: activeStory !== null });
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar dados do perfil'));
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
