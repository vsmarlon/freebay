import {
  Controller,
  Body,
  Param,
  HttpStatus,
  UseInterceptors,
  ParseUUIDPipe,
  Headers,
  Put,
  Delete,
  UploadedFiles,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { deleteUpload, saveUpload } from "@/shared/utils/file.utils";
import {
  CreatePostDTO,
  CreateCommentDTO,
  SetReplyPermissionDTO,
  SetConversationPreferenceDTO,
  ReportCommentDTO,
} from "./dtos/social.dto";
import { validateMediaFile, MAX_MEDIA_SIZE } from "@/shared/utils/image-upload.utils";
import {
  PostAuth,
  PatchAuth,
  CurrentUserId,
  Auth,
} from "@/shared/decorators";
import { left } from "@/shared/core/either";
import { BadRequestError } from "@/shared/core/errors";
import { StoryAudience } from '@prisma/client';
import { generateImageBlurHash } from '@/shared/utils/blurhash.utils';
import { ALLOWED_IMAGE_MIMES, ALLOWED_VIDEO_MIMES, hasValidMagicBytes } from '@/shared/utils/image-upload.utils';
import { BoundedMultipartInterceptor } from '@/shared/interceptors/bounded-multipart.interceptor';
import { parsePublicationMedia, PublicationMediaDescriptor, validatePublicationMediaFiles } from '@/shared/media/publication-media';
import { THROTTLE_TTL_MINUTE_MS } from '@/shared/http/throttle.constants';

const PUBLICATION_UPLOAD_MAX_BYTES = 100 * 1024 * 1024;
const PUBLICATION_METADATA_MAX_BYTES = 256 * 1024;

// Direct UseCases
import { CreatePostUseCase } from "./usecases/create-post.usecase";
import { CommentUseCase } from "./usecases/comment.usecase";
import { LikePostUseCase } from "./usecases/like-post.usecase";
import { UnlikePostUseCase } from "./usecases/unlike-post.usecase";
import { SharePostUseCase } from "./usecases/share-post.usecase";
import { UnsharePostUseCase } from "./usecases/unshare-post.usecase";
import { SavePostUseCase } from "./usecases/save-post.usecase";
import { UnsavePostUseCase } from "./usecases/unsave-post.usecase";
import { LikeCommentUseCase } from "./usecases/like-comment.usecase";
import { UnlikeCommentUseCase } from "./usecases/unlike-comment.usecase";
import { DeletePostUseCase } from "./usecases/delete-post.usecase";
import { DeleteCommentUseCase } from "./usecases/delete-comment.usecase";
import { ApproveCommentUseCase } from './usecases/approve-comment.usecase';
import { ManageCommentVisibilityUseCase } from './usecases/manage-comment-visibility.usecase';
import { ManageCommentInteractionsUseCase } from './usecases/manage-comment-interactions.usecase';

const COMMENT_MEDIA_MAX_BYTES = 20 * 1024 * 1024;
const COMMENT_MEDIA_MIMES: ReadonlySet<string> = new Set([...ALLOWED_IMAGE_MIMES, ...ALLOWED_VIDEO_MIMES]);

@ApiTags("Social")
@Controller("social")
export class SocialWriteController {
  constructor(
    private readonly createPostUseCase: CreatePostUseCase,
    private readonly commentUseCase: CommentUseCase,
    private readonly likePostUseCase: LikePostUseCase,
    private readonly unlikePostUseCase: UnlikePostUseCase,
    private readonly sharePostUseCase: SharePostUseCase,
    private readonly unsharePostUseCase: UnsharePostUseCase,
    private readonly savePostUseCase: SavePostUseCase,
    private readonly unsavePostUseCase: UnsavePostUseCase,
    private readonly likeCommentUseCase: LikeCommentUseCase,
    private readonly unlikeCommentUseCase: UnlikeCommentUseCase,
    private readonly deletePostUseCase: DeletePostUseCase,
    private readonly deleteCommentUseCase: DeleteCommentUseCase,
    private readonly approveCommentUseCase: ApproveCommentUseCase,
    private readonly manageCommentVisibilityUseCase: ManageCommentVisibilityUseCase,
    private readonly manageCommentInteractionsUseCase: ManageCommentInteractionsUseCase,
  ) {}

  @PostAuth("posts", {
    summary: "Create a post",
    description: "Creates a social post with an optional collection of up to 10 ordered images or videos",
    bodyType: CreatePostDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
    throttle: { short: { limit: 5, ttl: THROTTLE_TTL_MINUTE_MS } },
  })
  @UseInterceptors(
    BoundedMultipartInterceptor("files", 20, PUBLICATION_UPLOAD_MAX_BYTES, PUBLICATION_METADATA_MAX_BYTES, MAX_MEDIA_SIZE),
  )
  async createPost(
    @CurrentUserId() userId: string,
    @UploadedFiles() files: Express.Multer.File[] = [],
    @Body() body: CreatePostDTO,
  ) {
    for (const file of files) {
      const mimeError = validateMediaFile(file);
      if (mimeError) return left(new BadRequestError(mimeError));
    }
    let descriptors: PublicationMediaDescriptor[] = [];
    try {
      if (files.length > 0 || body.mediaMetadata != null) {
        descriptors = parsePublicationMedia(body.mediaMetadata, files.length);
        validatePublicationMediaFiles(descriptors, files);
      }
    } catch (error) {
      return left(new BadRequestError(error instanceof Error ? error.message : 'Metadados de mídia inválidos'));
    }
    const closeFriends = body.audience === StoryAudience.CLOSE_FRIENDS;
    const savedUrls: string[] = [];
    try {
      for (const file of files) savedUrls.push(saveUpload(file, closeFriends ? 'privatepost' : 'post'));
      const media = await Promise.all(descriptors.map(async (descriptor) => {
        const blurFile = files[descriptor.thumbnailFileIndex ?? descriptor.fileIndex];
        return {
          url: savedUrls[descriptor.fileIndex],
          ...(descriptor.thumbnailFileIndex == null ? {} : { thumbnailUrl: savedUrls[descriptor.thumbnailFileIndex] }),
          type: descriptor.type,
          blurHash: closeFriends ? undefined : await generateImageBlurHash(blurFile.buffer),
          altText: descriptor.altText,
          durationMs: descriptor.durationMs,
          coverTimestampMs: descriptor.coverTimestampMs,
          hotspots: descriptor.hotspots,
        };
      }));
      const { mediaMetadata: _mediaMetadata, ...post } = body;
      const result = await this.createPostUseCase.execute({
        userId,
        ...post,
        media: media.length ? media : undefined,
      });
      if (result.isLeft()) savedUrls.forEach(deleteUpload);
      return result;
    } catch (error) {
      savedUrls.forEach(deleteUpload);
      throw error;
    }
  }

  @PatchAuth("posts/:id/delete", {
    summary: "Soft-delete a post",
    params: [{ name: "id", description: "Post UUID" }],
    errors: [{ status: 404, description: "Post not found" }],
  })
  async deletePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.deletePostUseCase.execute({ postId: id, userId });
  }

  @PatchAuth("comments/:id/delete", {
    summary: "Soft-delete a comment",
    params: [{ name: "id", description: "Comment UUID" }],
    errors: [{ status: 404, description: "Comment not found" }],
  })
  async deleteComment(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.deleteCommentUseCase.execute({ commentId: id, userId });
  }

  @PatchAuth('comments/:id/approve', 'Approve a hidden comment on your post')
  async approveComment(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.approveCommentUseCase.execute(id, userId);
  }

  @PatchAuth('comments/:id/hide', 'Hide a reply on your post')
  async hideComment(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.manageCommentVisibilityUseCase.execute(id, userId, true);
  }

  @PatchAuth('comments/:id/unhide', 'Unhide a reply on your post')
  async unhideComment(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.manageCommentVisibilityUseCase.execute(id, userId, false);
  }

  @PatchAuth('posts/:id/reply-permission', { summary: 'Set who may reply to a post', bodyType: SetReplyPermissionDTO })
  async setReplyPermission(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string, @Body() body: SetReplyPermissionDTO) {
    return this.manageCommentVisibilityUseCase.setPermission(id, userId, body.permission);
  }

  @Put('posts/:id/subscription')
  @Auth({ summary: 'Follow or unfollow conversation replies', bodyType: SetConversationPreferenceDTO })
  async setConversationSubscription(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string, @Body() body: SetConversationPreferenceDTO) {
    return this.manageCommentVisibilityUseCase.setConversationPreference(id, userId, body.enabled, false);
  }

  @Put('posts/:id/mute')
  @Auth({ summary: 'Mute or unmute conversation notifications', bodyType: SetConversationPreferenceDTO })
  async setConversationMute(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string, @Body() body: SetConversationPreferenceDTO) {
    return this.manageCommentVisibilityUseCase.setConversationPreference(id, userId, body.enabled, true);
  }

  @PostAuth("posts/:id/like", {
    summary: "Like a post",
    params: [{ name: "id", description: "Post UUID" }],
  })
  async likePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.likePostUseCase.execute({ userId, postId: id });
  }

  @PatchAuth("posts/:id/unlike", {
    summary: "Unlike a post",
    params: [{ name: "id", description: "Post UUID" }],
  })
  async unlikePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unlikePostUseCase.execute({ userId, postId: id });
  }

  @PostAuth("posts/:id/share", {
    summary: "Share/repost a post",
    responseStatus: 201,
    params: [{ name: "id", description: "Post UUID" }],
    httpCode: HttpStatus.CREATED,
  })
  async sharePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.sharePostUseCase.execute({ userId, postId: id });
  }

  @PatchAuth("posts/:id/unshare", {
    summary: "Remove share/repost",
    params: [{ name: "id", description: "Post UUID" }],
    httpCode: HttpStatus.OK,
  })
  async unsharePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unsharePostUseCase.execute({ userId, postId: id });
  }

  @PostAuth("posts/:id/comments", {
    summary: "Create comment on post",
    responseStatus: 201,
    params: [{ name: "id", description: "Post UUID" }],
    bodyType: CreateCommentDTO,
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(BoundedMultipartInterceptor('media', 4, COMMENT_MEDIA_MAX_BYTES))
  async createComment(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
    @Body() body: CreateCommentDTO,
    @Headers('idempotency-key') headerKey?: string,
    @UploadedFiles() files: Express.Multer.File[] = [],
  ) {
    if (files.length > 4 || files.reduce((total, file) => total + file.size, 0) > COMMENT_MEDIA_MAX_BYTES) {
      return left(new BadRequestError('Comment media exceeds the 20 MiB request limit'));
    }
    for (const file of files) {
      if (!COMMENT_MEDIA_MIMES.has(file.mimetype) || file.size !== file.buffer.length || !hasValidMagicBytes(file.buffer, file.mimetype)) {
        return left(new BadRequestError(`Unsupported or invalid comment media: ${file.mimetype}`));
      }
    }
    const normalizedHeaderKey = headerKey?.trim();
    if (normalizedHeaderKey && normalizedHeaderKey.length > 128) return left(new BadRequestError('Idempotency-Key is too long'));
    if (normalizedHeaderKey && body.clientRequestId && normalizedHeaderKey !== body.clientRequestId) {
      return left(new BadRequestError('Idempotency-Key and clientRequestId must match'));
    }
    return this.commentUseCase.execute({
      userId,
      postId: id,
      content: body.content,
      parentId: body.parentId,
      mentionIds: body.mentionIds,
      clientRequestId: normalizedHeaderKey || body.clientRequestId,
      ...(files.length > 0 ? { media: files } : {}),
    });
  }

  @PostAuth("comments/:commentId/like", {
    summary: "Like a comment",
    params: [{ name: "commentId", description: "Comment UUID" }],
  })
  async likeComment(
    @Param("commentId", ParseUUIDPipe) commentId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.likeCommentUseCase.execute({ userId, commentId });
  }

  @PatchAuth("comments/:commentId/unlike", {
    summary: "Unlike a comment",
    params: [{ name: "commentId", description: "Comment UUID" }],
  })
  async unlikeComment(
    @Param("commentId", ParseUUIDPipe) commentId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unlikeCommentUseCase.execute({ userId, commentId });
  }

  @PostAuth('comments/:commentId/repost', { summary: 'Repost a comment', responseStatus: 201, httpCode: HttpStatus.CREATED })
  async repostComment(@Param('commentId', ParseUUIDPipe) commentId: string, @CurrentUserId() userId: string) {
    return this.manageCommentInteractionsUseCase.repost(userId, commentId);
  }

  @PatchAuth('comments/:commentId/unrepost', { summary: 'Remove a comment repost' })
  async unrepostComment(@Param('commentId', ParseUUIDPipe) commentId: string, @CurrentUserId() userId: string) {
    return this.manageCommentInteractionsUseCase.unrepost(userId, commentId);
  }

  @Put('comments/:commentId/bookmark')
  @Auth({ summary: 'Bookmark a comment' })
  async bookmarkComment(@Param('commentId', ParseUUIDPipe) commentId: string, @CurrentUserId() userId: string) {
    return this.manageCommentInteractionsUseCase.bookmark(userId, commentId, true);
  }

  @Delete('comments/:commentId/bookmark')
  @Auth({ summary: 'Remove a comment bookmark' })
  async unbookmarkComment(@Param('commentId', ParseUUIDPipe) commentId: string, @CurrentUserId() userId: string) {
    return this.manageCommentInteractionsUseCase.bookmark(userId, commentId, false);
  }

  @PostAuth('comments/:commentId/report', { summary: 'Report a comment', bodyType: ReportCommentDTO, responseStatus: 201, httpCode: HttpStatus.CREATED })
  async reportComment(@Param('commentId', ParseUUIDPipe) commentId: string, @CurrentUserId() userId: string, @Body() body: ReportCommentDTO) {
    return this.manageCommentInteractionsUseCase.report(userId, commentId, body.reason, body.description);
  }

  @PostAuth("posts/:id/save", {
    summary: "Save a post",
    responseStatus: 201,
    params: [{ name: "id", description: "Post UUID" }],
    httpCode: HttpStatus.CREATED,
  })
  async savePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.savePostUseCase.execute({ userId, postId: id });
  }

  @PatchAuth("posts/:id/unsave", {
    summary: "Unsave a post",
    params: [{ name: "id", description: "Post UUID" }],
  })
  async unsavePost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unsavePostUseCase.execute({ userId, postId: id });
  }
}
