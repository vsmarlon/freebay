import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { User } from '@prisma/client';

// ─── Swagger response classes ──────────────────────────

export class UserResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'John Doe' })
  displayName: string;

  @ApiPropertyOptional({ example: null, nullable: true })
  avatarUrl: string | null;

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

export class SuggestionResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'Jane Doe' })
  displayName: string;

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

export const toUserResponse = (user: User): UserResponse => ({
  id: user.id,
  displayName: user.displayName,
  avatarUrl: user.avatarUrl,
  bio: user.bio,
  city: user.city,
  state: user.state,
  isVerified: user.isVerified,
  reputationScore: user.reputationScore,
  totalReviews: user.totalReviews,
  createdAt: user.createdAt,
  role: user.role,
  hasCpf: !!user.cpf,
});
