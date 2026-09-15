import {
  Controller,
  Body,
  Param,
  Query,
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
  GetFeedQueryDTO,
  GetUserPostsQueryDTO,
  SearchPostsQueryDTO,
  GetCommentsQueryDTO,
} from "./dtos/social.dto";
import { validateImageFile } from "@/shared/utils/image-upload.utils";
import {
  GetAuth,
  GetPublic,
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
import { GetPostUseCase } from "./usecases/get-post.usecase";
import { GetFeedUseCase } from "./usecases/get-feed.usecase";
import { GetUserPostsUseCase } from "./usecases/get-user-posts.usecase";
import { GetUserRepostsUseCase } from "./usecases/get-user-reposts.usecase";
import { SearchPostsUseCase } from "./usecases/search-posts.usecase";
import { GetCommentsUseCase } from "./usecases/get-comments.usecase";
import { GetLikedPostsUseCase } from "./usecases/get-liked-posts.usecase";
import { SharePostUseCase } from "./usecases/share-post.usecase";
import { UnsharePostUseCase } from "./usecases/unshare-post.usecase";
import { SavePostUseCase } from "./usecases/save-post.usecase";
import { UnsavePostUseCase } from "./usecases/unsave-post.usecase";
import { LikeCommentUseCase } from "./usecases/like-comment.usecase";
import { UnlikeCommentUseCase } from "./usecases/unlike-comment.usecase";
import { DeletePostUseCase } from "./usecases/delete-post.usecase";
import { DeleteCommentUseCase } from "./usecases/delete-comment.usecase";
import { GetSavedPostsUseCase } from "./usecases/get-saved-posts.usecase";

@ApiTags("Social")
@Controller("social")
export class SocialController {
  constructor(
    private readonly createPostUseCase: CreatePostUseCase,
    private readonly commentUseCase: CommentUseCase,
    private readonly likePostUseCase: LikePostUseCase,
    private readonly unlikePostUseCase: UnlikePostUseCase,
    private readonly getPostUseCase: GetPostUseCase,
    private readonly getFeedUseCase: GetFeedUseCase,
    private readonly getUserPostsUseCase: GetUserPostsUseCase,
    private readonly getUserRepostsUseCase: GetUserRepostsUseCase,
    private readonly searchPostsUseCase: SearchPostsUseCase,
    private readonly getCommentsUseCase: GetCommentsUseCase,
    private readonly getLikedPostsUseCase: GetLikedPostsUseCase,
    private readonly sharePostUseCase: SharePostUseCase,
    private readonly unsharePostUseCase: UnsharePostUseCase,
    private readonly savePostUseCase: SavePostUseCase,
    private readonly unsavePostUseCase: UnsavePostUseCase,
    private readonly likeCommentUseCase: LikeCommentUseCase,
    private readonly unlikeCommentUseCase: UnlikeCommentUseCase,
    private readonly deletePostUseCase: DeletePostUseCase,
    private readonly deleteCommentUseCase: DeleteCommentUseCase,
    private readonly getSavedPostsUseCase: GetSavedPostsUseCase,
  ) {}

  @GetPublic("feed", {
    summary: "Get social feed",
    description:
      "Returns paginated feed of posts from followed users or explore",
  })
  async getFeed(
    @CurrentUserId() userId: string,
    @Query() query: GetFeedQueryDTO,
  ) {
    return this.getFeedUseCase.execute({
      userId: userId || "",
      limit: query.limit ?? 20,
      type: query.type ?? "explore",
      cursor: query.cursor,
      offset: query.offset,
      contentFilter: query.contentFilter,
    });
  }

  @GetPublic("posts/search", {
    summary: "Search posts",
  })
  async searchPosts(
    @CurrentUserId() userId: string,
    @Query() query: SearchPostsQueryDTO,
  ) {
    return this.searchPostsUseCase.execute({
      query: query.q || "",
      filter: query.filter || "all",
      userId: userId || "",
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @GetAuth("posts/liked", "Get liked posts")
  async getLikedPosts(@CurrentUserId() userId: string) {
    return this.getLikedPostsUseCase.execute(userId);
  }

  @GetAuth("posts/saved", "Get saved posts")
  async getSavedPosts(
    @CurrentUserId() userId: string,
    @Query() query: GetUserPostsQueryDTO,
  ) {
    return this.getSavedPostsUseCase.execute({
      userId,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @GetPublic("posts/user/:userId", {
    summary: "Get user posts",
    description: "Returns posts owned by a specific user",
    params: [{ name: "userId", description: "User UUID" }],
  })
  async getUserPosts(
    @Param("userId", ParseUUIDPipe) userId: string,
    @Query() query: GetUserPostsQueryDTO,
    @CurrentUserId() viewerId: string,
  ) {
    return this.getUserPostsUseCase.execute({
      userId,
      viewerId: viewerId || undefined,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @GetPublic("posts/user/:userId/reposts", {
    summary: "Get user reposts",
    params: [{ name: "userId", description: "User UUID" }],
  })
  async getUserReposts(
    @Param("userId", ParseUUIDPipe) userId: string,
    @Query() query: GetUserPostsQueryDTO,
    @CurrentUserId() viewerId: string,
  ) {
    return this.getUserRepostsUseCase.execute({
      userId,
      viewerId: viewerId || undefined,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
  }

  @GetPublic("posts/:id", {
    summary: "Get post by ID",
    params: [{ name: "id", description: "Post UUID" }],
    errors: [{ status: 404, description: "Post not found" }],
  })
  async getPost(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() viewerId: string,
  ) {
    return this.getPostUseCase.execute({ id, viewerId: viewerId || undefined });
  }

  @GetPublic("posts/:id/comments", {
    summary: "Get comments for a post",
    params: [{ name: "id", description: "Post UUID" }],
  })
  async getComments(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() viewerId: string,
    @Query() query: GetCommentsQueryDTO,
  ) {
    return this.getCommentsUseCase.execute({
      postId: id,
      viewerId: viewerId || undefined,
      limit: query.limit ?? 20,
      offset: query.offset ?? 0,
    });
  }

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
