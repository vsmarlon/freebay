import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsUUID,
  IsIn,
  IsUrl,
  IsInt,
  Min,
  Max,
  IsArray,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { SanitizeText } from "@/shared/utils/sanitize.decorator";

export class CreatePostDTO {
  @ApiPropertyOptional({ example: "Post content here..." })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly content?: string;

  @ApiPropertyOptional({ example: "https://example.com/image.jpg" })
  @IsOptional()
  @IsUrl({ require_protocol: true, protocols: ["https"] })
  readonly imageUrl?: string;

  @ApiProperty({ enum: ["PRODUCT", "REGULAR"], example: "REGULAR" })
  @IsIn(["PRODUCT", "REGULAR"])
  readonly type: "PRODUCT" | "REGULAR";

  @ApiPropertyOptional({
    example: ["uuid1", "uuid2"],
    required: false,
    type: [String],
  })
  @IsArray()
  @IsOptional()
  @IsUUID("all", { each: true })
  readonly mentionIds?: string[];
}

export class CreateCommentDTO {
  @ApiProperty({ example: "Great post!", minLength: 1, maxLength: 1000 })
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  @SanitizeText()
  readonly content: string;

  @ApiPropertyOptional({ example: "parent-uuid" })
  @IsOptional()
  @IsUUID()
  readonly parentId?: string;

  @ApiPropertyOptional({
    example: ["uuid1", "uuid2"],
    required: false,
    type: [String],
  })
  @IsArray()
  @IsOptional()
  @IsUUID("all", { each: true })
  readonly mentionIds?: string[];
}

export class GetFeedQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;

  @ApiPropertyOptional({ enum: ["explore", "following"], example: "explore" })
  @IsOptional()
  @IsIn(["explore", "following"])
  readonly type?: "explore" | "following";

  @ApiPropertyOptional({
    description: "Keyset pagination cursor (type=following only)",
  })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({
    description: "Page offset (type=explore only)",
    example: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly offset?: number;

  @ApiPropertyOptional({ enum: ["all", "social", "selling"], example: "all" })
  @IsOptional()
  @IsIn(["all", "social", "selling"])
  readonly contentFilter?: "all" | "social" | "selling";
}

export class GetUserPostsQueryDTO {
  @ApiPropertyOptional({ description: "Pagination cursor" })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;
}

export class GetCommentsQueryDTO {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly offset?: number;
}

export class SearchPostsQueryDTO {
  @ApiPropertyOptional({ description: "Search query" })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  readonly q?: string;

  @ApiPropertyOptional({
    enum: ["all", "following", "followers"],
    example: "all",
  })
  @IsOptional()
  @IsIn(["all", "following", "followers"])
  readonly filter?: "all" | "following" | "followers";

  @ApiPropertyOptional({ description: "Pagination cursor" })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;
}

export interface CreatePostInput {
  userId: string;
  content?: string;
  imageUrl?: string;
  type: "PRODUCT" | "REGULAR";
  mentionIds?: string[];
}

export interface CreatePostOutput {
  id: string;
  content: string | null;
  imageUrl: string | null;
  type: "PRODUCT" | "REGULAR";
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
  mentionIds?: string[];
}

export interface CreateCommentOutput {
  id: string;
  postId: string;
  userId: string;
  content: string;
  createdAt: Date;
}
