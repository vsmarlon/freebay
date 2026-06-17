import { IsString, MinLength, MaxLength, IsOptional, IsUUID, IsIn, IsUrl } from 'class-validator';
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
  createdAt: Date;
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
