import {
  Controller,
  Param,
  Query,
  ParseUUIDPipe,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import {
  GetFeedQueryDTO,
  GetUserPostsQueryDTO,
  SearchPostsQueryDTO,
  GetCommentsQueryDTO,
} from "./dtos/social.dto";
import {
  GetAuth,
  GetPublic,
  CurrentUserId,
} from "@/shared/decorators";

// Direct UseCases
import { GetPostUseCase } from "./usecases/get-post.usecase";
import { GetFeedUseCase } from "./usecases/get-feed.usecase";
import { GetUserPostsUseCase } from "./usecases/get-user-posts.usecase";
import { GetProfileTimelineUseCase } from './usecases/get-profile-timeline.usecase';
import { GetUserRepostsUseCase } from "./usecases/get-user-reposts.usecase";
import { SearchPostsUseCase } from "./usecases/search-posts.usecase";
import { GetCommentsUseCase } from "./usecases/get-comments.usecase";
import { GetLikedPostsUseCase } from "./usecases/get-liked-posts.usecase";
import { GetSavedPostsUseCase } from "./usecases/get-saved-posts.usecase";
import { FeedType } from "./types/social.types";

@ApiTags("Social")
@Controller("social")
export class SocialReadController {
  constructor(
    private readonly getPostUseCase: GetPostUseCase,
    private readonly getFeedUseCase: GetFeedUseCase,
    private readonly getUserPostsUseCase: GetUserPostsUseCase,
    private readonly getProfileTimelineUseCase: GetProfileTimelineUseCase,
    private readonly getUserRepostsUseCase: GetUserRepostsUseCase,
    private readonly searchPostsUseCase: SearchPostsUseCase,
    private readonly getCommentsUseCase: GetCommentsUseCase,
    private readonly getLikedPostsUseCase: GetLikedPostsUseCase,
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
      type: query.type ?? FeedType.EXPLORE,
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

  @GetPublic('posts/user/:userId/timeline', { summary: 'Get paginated profile posts and reposts' })
  async getProfileTimeline(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: GetUserPostsQueryDTO,
    @CurrentUserId() viewerId: string,
  ) {
    return this.getProfileTimelineUseCase.execute({
      userId, viewerId: viewerId || undefined,
      limit: query.limit ?? 20, cursor: query.cursor, kind: query.kind,
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
}
