import { IsString, MinLength, MaxLength, IsOptional, IsUUID, IsIn, IsUrl, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class CreatePostDTO {
  @ApiPropertyOptional({ example: 'Post content here...' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  content?: string;

  @ApiPropertyOptional({ example: 'https://example.com/image.jpg' })
  @IsOptional()
  @IsUrl({ require_protocol: true, protocols: ['https'] })
  imageUrl?: string;

  @ApiProperty({ enum: ['PRODUCT', 'REGULAR'], example: 'REGULAR' })
  @IsIn(['PRODUCT', 'REGULAR'])
  type: 'PRODUCT' | 'REGULAR';
}

export class CreateCommentDTO {
  @ApiProperty({ example: 'Great post!', minLength: 1, maxLength: 1000 })
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  @SanitizeText()
  content: string;

  @ApiPropertyOptional({ example: 'parent-uuid' })
  @IsOptional()
  @IsUUID()
  parentId?: string;
}

export class GetFeedQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({ enum: ['explore', 'following'], example: 'explore' })
  @IsOptional()
  @IsIn(['explore', 'following'])
  type?: 'explore' | 'following';
}

export class GetUserPostsQueryDTO {
  @ApiPropertyOptional({ description: 'Pagination cursor' })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}

export class SearchPostsQueryDTO {
  @ApiPropertyOptional({ description: 'Search query' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  q?: string;

  @ApiPropertyOptional({ enum: ['all', 'following', 'followers'], example: 'all' })
  @IsOptional()
  @IsIn(['all', 'following', 'followers'])
  filter?: 'all' | 'following' | 'followers';

  @ApiPropertyOptional({ description: 'Pagination cursor' })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}

export interface CreatePostInput {
  userId: string;
  content?: string;
  imageUrl?: string;
  type: 'PRODUCT' | 'REGULAR';
}

export interface CreatePostOutput {
  id: string;
  content: string | null;
  imageUrl: string | null;
  type: 'PRODUCT' | 'REGULAR';
  userId: string;
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  createdAt: Date;
  user: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export interface LikePostInput {
  userId: string;
  postId: string;
}

export interface CreateCommentInput {
  userId: string;
  postId: string;
  content: string;
  parentId?: string;
}

export interface CreateCommentOutput {
  id: string;
  postId: string;
  userId: string;
  content: string;
  createdAt: Date;
}

export interface CreateStoryInput {
  userId: string;
  imageBase64: string;
}

export interface CreateStoryOutput {
  id: string;
  userId: string;
  imageUrl: string;
  createdAt: Date;
}
