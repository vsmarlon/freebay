import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { User } from '@prisma/client';

// ─── Swagger response classes ──────────────────────────

export class UserResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'John Doe' })
  displayName: string;

  @ApiPropertyOptional({ example: 'john_doe', nullable: true })
  username: string | null;

  @ApiPropertyOptional({ example: null, nullable: true })
  avatarUrl: string | null;

  @ApiPropertyOptional({ example: null, nullable: true })
  bannerUrl: string | null;

  @ApiPropertyOptional({ example: null, nullable: true })
  bio: string | null;

  @ApiPropertyOptional({ example: 'São Paulo', nullable: true })
  city: string | null;

  @ApiPropertyOptional({ example: 'SP', nullable: true })
  state: string | null;

  @ApiProperty({ example: false })
  isVerified: boolean;

  @ApiProperty({ example: 4.5 })
  reputationScore: number;

  @ApiProperty({ example: 42 })
  totalReviews: number;

  @ApiProperty({ example: '2026-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: 'USER' })
  role: string;

  @ApiProperty({ example: true })
  hasCpf: boolean;

  @ApiPropertyOptional({ example: '123.***.***-00' })
  cpf?: string;

  @ApiPropertyOptional({ example: '2026-09-06T10:30:00.000Z', nullable: true })
  deletionRequestedAt?: Date | null;

  @ApiPropertyOptional({ example: null, nullable: true })
  suspendedAt?: Date | null;

  @ApiProperty({ example: 12 })
  postsCount: number;

  @ApiProperty({ example: 5 })
  productsCount: number;

  @ApiProperty({ example: false })
  hasActiveStory: boolean;
}

export class UserStatsResponse {
  @ApiProperty({ example: 12 })
  salesCount: number;

  @ApiProperty({ example: 8 })
  purchasesCount: number;

  @ApiProperty({ example: 150 })
  followersCount: number;

  @ApiProperty({ example: 85 })
  followingCount: number;
}

export class FollowResponse {
  @ApiProperty({ example: true })
  following: boolean;

  @ApiProperty({ example: 150 })
  followersCount: number;

  @ApiProperty({ example: 85 })
  followingCount: number;
}

export class BlockResponse {
  @ApiProperty({ example: true })
  blocked: boolean;
}

export class SearchUserResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'John Doe' })
  displayName: string;

  @ApiPropertyOptional({ example: 'john_doe', nullable: true })
  username: string | null;

  @ApiPropertyOptional({ nullable: true })
  avatarUrl: string | null;

  @ApiPropertyOptional({ nullable: true })
  bio: string | null;

  @ApiProperty({ example: false })
  isVerified: boolean;

  @ApiProperty({ example: 4.5 })
  reputationScore: number;

  @ApiProperty({ example: 42 })
  totalReviews: number;

  @ApiProperty({ example: 150 })
  followersCount: number;

  @ApiProperty({ example: 85 })
  followingCount: number;
}

export class AccountDeletionResponse {
  @ApiProperty({ example: '2026-09-06T10:30:00.000Z' })
  deletionRequestedAt: Date;

  @ApiProperty({ example: '2026-10-06T10:30:00.000Z' })
  purgeAfter: Date;
}

export class SuggestionResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'Jane Doe' })
  displayName: string;

  @ApiPropertyOptional({ example: 'jane_doe', nullable: true })
  username: string | null;

  @ApiPropertyOptional({ nullable: true })
  avatarUrl: string | null;

  @ApiPropertyOptional({ nullable: true })
  bio: string | null;

  @ApiProperty({ example: false })
  isVerified: boolean;

  @ApiProperty({ example: 4.5 })
  reputationScore: number;

  @ApiProperty({ example: 42 })
  totalReviews: number;

  @ApiProperty({ example: 150 })
  followersCount: number;

  @ApiProperty({ example: 85 })
  followingCount: number;

  @ApiProperty({ example: 3 })
  mutualCount: number;
}

// ─── Mapper functions ──────────────────────────────────

export interface UserResponseExtras {
  postsCount?: number;
  productsCount?: number;
  hasActiveStory?: boolean;
}

export const toUserResponse = (
  user: User,
  extras?: UserResponseExtras,
  isOwner: boolean = false,
): UserResponse => ({
  id: user.id,
  displayName: user.displayName,
  username: user.username,
  avatarUrl: user.avatarUrl,
  bannerUrl: user.bannerUrl,
  bio: user.bio,
  city: user.city,
  state: user.state,
  isVerified: user.isVerified,
  reputationScore: user.reputationScore,
  totalReviews: user.totalReviews,
  createdAt: user.createdAt,
  role: isOwner ? user.role : 'USER',
  hasCpf: isOwner ? !!user.cpf : false,
  cpf: isOwner && user.cpf
    ? user.cpf.length === 11
      ? `${user.cpf.substring(0, 3)}.***.***-${user.cpf.substring(9)}`
      : user.cpf.length === 14
        ? `${user.cpf.substring(0, 2)}.***.***/****-${user.cpf.substring(12)}`
        : '***'
    : undefined,
  deletionRequestedAt: isOwner ? user.deletionRequestedAt : undefined,
  suspendedAt: isOwner ? user.suspendedAt : undefined,
  postsCount: extras?.postsCount ?? 0,
  productsCount: extras?.productsCount ?? 0,
  hasActiveStory: extras?.hasActiveStory ?? false,
});
