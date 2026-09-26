import {
  Controller,
  Body,
  Param,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  ParseUUIDPipe,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import { FileInterceptor } from "@nestjs/platform-express";
import { memoryStorage } from "multer";
import { saveUpload } from "@/shared/utils/file.utils";
import {
  CreatePostDTO,
  CreateCommentDTO,
} from "./dtos/social.dto";
import { validateImageFile } from "@/shared/utils/image-upload.utils";
import {
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from "@/shared/decorators";
import { left } from "@/shared/core/either";
import { BadRequestError } from "@/shared/core/errors";

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
  ) {}

  @PostAuth("posts", {
    summary: "Create a post",
    description: "Creates a new social post with optional image upload",
    bodyType: CreatePostDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(
    FileInterceptor("image", {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async createPost(
    @CurrentUserId() userId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreatePostDTO,
  ) {
    if (file) {
      const mimeError = validateImageFile(file);
      if (mimeError) return left(new BadRequestError(mimeError));
    }
    const imageUrl = file ? saveUpload(file, "post") : body.imageUrl;
    return this.createPostUseCase.execute({ userId, ...body, imageUrl });
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
  async createComment(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
    @Body() body: CreateCommentDTO,
  ) {
    return this.commentUseCase.execute({
      userId,
      postId: id,
      content: body.content,
      parentId: body.parentId,
      mentionIds: body.mentionIds,
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
