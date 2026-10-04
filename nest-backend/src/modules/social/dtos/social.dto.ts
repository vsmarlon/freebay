import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsUUID,
  IsEnum,
  IsInt,
  Min,
  Max,
  IsArray,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { PostType, StoryAudience } from "@prisma/client";
import { SanitizeText } from "@/shared/utils/sanitize.decorator";
import { COMMENT_MAX_LENGTH, ContentFilter, FeedType, ProfileTimelineKind, SEARCH_MAX_LENGTH, SearchFilter } from "../types/social.types";

export class CreatePostDTO {
  @ApiPropertyOptional({ enum: StoryAudience, default: StoryAudience.EVERYONE })
  @IsOptional()
  @IsEnum(StoryAudience)
  readonly audience?: StoryAudience;
  @ApiPropertyOptional({ example: "Post content here..." })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly content?: string;

  @ApiProperty({ enum: PostType, example: PostType.REGULAR })
  @IsEnum(PostType)
  readonly type: PostType;

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
  @ApiProperty({ example: "Great post!", minLength: 1, maxLength: COMMENT_MAX_LENGTH })
  @IsString()
  @MinLength(1)
  @MaxLength(COMMENT_MAX_LENGTH)
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

  @ApiPropertyOptional({ enum: FeedType, example: FeedType.EXPLORE })
  @IsOptional()
  @IsEnum(FeedType)
  readonly type?: FeedType;

  @ApiPropertyOptional({
    description: "Opaque pagination cursor for Explore and Following feeds",
  })
  @IsOptional()
  @IsString()
  readonly cursor?: string;

  @ApiPropertyOptional({
    description: "Legacy first-page offset; use cursor for subsequent Explore pages",
    example: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly offset?: number;

  @ApiPropertyOptional({ enum: ContentFilter, example: ContentFilter.ALL })
  @IsOptional()
  @IsEnum(ContentFilter)
  readonly contentFilter?: ContentFilter;
}

export class GetUserPostsQueryDTO {
  @ApiPropertyOptional({ enum: ProfileTimelineKind })
  @IsOptional()
  @IsEnum(ProfileTimelineKind)
  readonly kind?: ProfileTimelineKind;

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
  @MaxLength(SEARCH_MAX_LENGTH)
  readonly q?: string;

  @ApiPropertyOptional({ enum: SearchFilter, example: SearchFilter.ALL })
  @IsOptional()
  @IsEnum(SearchFilter)
  readonly filter?: SearchFilter;

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
  imageBlurHash?: string;
  type: PostType;
  audience?: StoryAudience;
  mentionIds?: string[];
}

export interface CreatePostOutput {
  id: string;
  content: string | null;
  imageUrl: string | null;
  imageBlurHash?: string;
  type: PostType;
  audience: StoryAudience;
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
