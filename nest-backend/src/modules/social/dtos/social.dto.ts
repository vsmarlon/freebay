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
  IsIn,
  IsBoolean,
  ValidateBy,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { CommentReplyPermission, PostType, ReportReason, StoryAudience } from "@prisma/client";
import { SanitizeText } from "@/shared/utils/sanitize.decorator";
import { COMMENT_MAX_LENGTH, ContentFilter, FeedType, ProfileTimelineKind, QUOTE_MAX_LENGTH, SEARCH_MAX_LENGTH, SearchFilter } from "../types/social.types";
import { PublicationMediaInput, PublicationMediaResponse } from '@/shared/media/publication-media';
import { CommentSort } from '../types/comment-cursor';

const commentGraphemeSegmenter = new Intl.Segmenter(undefined, {
  granularity: 'grapheme',
});

export class CreatePostDTO {
  @ApiPropertyOptional({ description: 'Ordered JSON media metadata matching multipart files' })
  @IsOptional()
  @IsString()
  readonly mediaMetadata?: string;

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
  @ValidateBy({
    name: 'maxCommentGraphemeLength',
    validator: {
      validate(value: unknown) {
        if (typeof value !== 'string') return false;
        let count = 0;
        for (const _segment of commentGraphemeSegmenter.segment(value)) {
          if (++count > COMMENT_MAX_LENGTH) return false;
        }
        return true;
      },
      defaultMessage: () =>
        `content must be shorter than or equal to ${COMMENT_MAX_LENGTH} characters`,
    },
  })
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

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  readonly clientRequestId?: string;
}

export class CreateQuoteDTO {
  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional() @IsUUID()
  readonly sourcePostId?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional() @IsUUID()
  readonly sourceCommentId?: string;

  @ApiProperty({ minLength: 1, maxLength: QUOTE_MAX_LENGTH })
  @IsString() @MinLength(1) @MaxLength(QUOTE_MAX_LENGTH) @SanitizeText()
  readonly content!: string;

  @ApiPropertyOptional({ type: [String], example: ['uuid'] })
  @IsArray() @IsOptional() @IsUUID('all', { each: true })
  readonly mentionIds?: string[];

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional() @IsUUID()
  readonly clientRequestId?: string;
}

export class ConversationQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50)
  readonly limit?: number;
  @ApiPropertyOptional({ description: 'Opaque keyset cursor' })
  @IsOptional() @IsString() @MaxLength(4096)
  readonly cursor?: string;
  @ApiPropertyOptional({ enum: CommentSort })
  @IsOptional() @IsIn(Object.values(CommentSort))
  readonly sort?: CommentSort;
}

export class CommentContextQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50)
  readonly replyLimit?: number;
  @ApiPropertyOptional({ description: 'Opaque direct-reply cursor' })
  @IsOptional() @IsString() @MaxLength(4096)
  readonly replyCursor?: string;
  @ApiPropertyOptional({ enum: CommentSort })
  @IsOptional() @IsIn(Object.values(CommentSort))
  readonly replySort?: CommentSort;
  @ApiPropertyOptional({ description: 'Opaque ancestor continuation cursor' })
  @IsOptional() @IsString() @MaxLength(4096)
  readonly ancestorCursor?: string;
}

export class HiddenRepliesQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50)
  readonly limit?: number;
  @ApiPropertyOptional({ description: 'Opaque hidden-replies cursor' })
  @IsOptional() @IsString() @MaxLength(4096)
  readonly cursor?: string;
}

export class SetReplyPermissionDTO {
  @ApiProperty({ enum: CommentReplyPermission, default: CommentReplyPermission.EVERYONE })
  @IsEnum(CommentReplyPermission)
  readonly permission!: CommentReplyPermission;
}

export class SetConversationPreferenceDTO {
  @ApiProperty({ example: true })
  @IsBoolean()
  readonly enabled!: boolean;
}

export class CommentBookmarksQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50)
  readonly limit?: number;
  @ApiPropertyOptional({ description: 'Opaque bookmark cursor' })
  @IsOptional() @IsString() @MaxLength(4096)
  readonly cursor?: string;
}

export class ReportCommentDTO {
  @ApiProperty({ enum: ReportReason })
  @IsEnum(ReportReason)
  readonly reason!: ReportReason;

  @ApiPropertyOptional({ maxLength: 1000 })
  @IsOptional() @IsString() @MaxLength(1000) @SanitizeText()
  readonly description?: string;
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
  media?: PublicationMediaInput[];
  type: PostType;
  audience?: StoryAudience;
  mentionIds?: string[];
}

export interface CreatePostOutput {
  id: string;
  isQuote: false;
  content: string | null;
  media: PublicationMediaResponse[];
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
  clientRequestId?: string;
  media?: Express.Multer.File[];
}

export interface CreateCommentOutput {
  id: string;
  postId: string;
  userId: string;
  content: string;
  createdAt: Date;
  /** Fresh post.commentsCount after the idempotent write (visible comments only). */
  commentsCount: number;
  media?: Array<{ id: string; url: string; mimeType: string; size: number }>;
}

export interface CreateQuoteInput {
  userId: string;
  content: string;
  sourcePostId?: string;
  sourceCommentId?: string;
  mentionIds?: string[];
  clientRequestId?: string;
  image?: Express.Multer.File;
  imageBlurHash?: string;
}

export interface DeletePostInput {
  postId: string;
  userId: string;
}

export interface DeleteCommentInput {
  commentId: string;
  userId: string;
}
