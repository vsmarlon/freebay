import {
  Controller,
  Param,
  Query,
  HttpStatus,
  ParseUUIDPipe,
} from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import {
  GetProfileUseCase,
  FollowUserUseCase,
  UnfollowUserUseCase,
  BlockUserUseCase,
  UnblockUserUseCase,
  ListFollowersUseCase,
  ListFollowingUseCase,
  GetFollowStatusUseCase,
  GetBlockStatusUseCase,
} from "./usecases";
import {
  GetAuth,
  GetPublic,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from "@/shared/decorators";
import { OffsetPaginationQueryDTO } from "./dtos/user.dto";
import {
  UserResponse,
  FollowResponse,
  BlockResponse,
} from "./mappers/user.mapper";

@ApiTags("Users")
@Controller("users")
export class UsersSocialController {
  constructor(
    private readonly getProfileUseCase: GetProfileUseCase,
    private readonly followUserUseCase: FollowUserUseCase,
    private readonly unfollowUserUseCase: UnfollowUserUseCase,
    private readonly blockUserUseCase: BlockUserUseCase,
    private readonly unblockUserUseCase: UnblockUserUseCase,
    private readonly listFollowersUseCase: ListFollowersUseCase,
    private readonly listFollowingUseCase: ListFollowingUseCase,
    private readonly getFollowStatusUseCase: GetFollowStatusUseCase,
    private readonly getBlockStatusUseCase: GetBlockStatusUseCase,
  ) {}

  @GetPublic(":id", {
    summary: "Get user by ID",
    params: [{ name: "id", description: "User UUID" }],
    responseType: UserResponse,
    errors: [{ status: 404, description: "User not found" }],
  })
  async getUser(@Param("id", ParseUUIDPipe) id: string) {
    return this.getProfileUseCase.execute({ userId: id });
  }

  @PostAuth(":id/follow", {
    summary: "Follow a user",
    params: [{ name: "id", description: "Target user UUID" }],
    responseType: FollowResponse,
    errors: [
      { status: 404, description: "User not found" },
      { status: 409, description: "Already following" },
    ],
    httpCode: HttpStatus.OK,
  })
  async followUser(
    @Param("id", ParseUUIDPipe) followingId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.followUserUseCase.execute({ followerId: userId, followingId });
  }

  @PatchAuth(":id/unfollow", {
    summary: "Unfollow a user",
    params: [{ name: "id", description: "Target user UUID" }],
    responseType: FollowResponse,
    errors: [{ status: 404, description: "Not following" }],
  })
  async unfollowUser(
    @Param("id", ParseUUIDPipe) followingId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unfollowUserUseCase.execute({
      followerId: userId,
      followingId,
    });
  }

  @GetAuth("me/followers", "Get current user followers")
  async getMyFollowers(@CurrentUserId() userId: string) {
    return this.listFollowersUseCase.execute({ userId, limit: 20, offset: 0 });
  }

  @GetAuth("me/following", "Get current user following")
  async getMyFollowing(@CurrentUserId() userId: string) {
    return this.listFollowingUseCase.execute({ userId, limit: 20, offset: 0 });
  }

  @GetPublic(":id/followers", {
    summary: "Get user followers",
    params: [{ name: "id", description: "User UUID" }],
    queries: [
      {
        name: "limit",
        required: false,
        description: "Results per page (default 20)",
      },
      {
        name: "offset",
        required: false,
        description: "Pagination offset (default 0)",
      },
    ],
    errors: [{ status: 404, description: "User not found" }],
  })
  async getFollowers(
    @Param("id", ParseUUIDPipe) id: string,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    return this.listFollowersUseCase.execute({
      userId: id,
      limit: query.limit ?? 20,
      offset: query.offset ?? 0,
      verifyUser: true,
    });
  }

  @GetPublic(":id/following", {
    summary: "Get users being followed",
    params: [{ name: "id", description: "User UUID" }],
    queries: [
      {
        name: "limit",
        required: false,
        description: "Results per page (default 20)",
      },
      {
        name: "offset",
        required: false,
        description: "Pagination offset (default 0)",
      },
    ],
    errors: [{ status: 404, description: "User not found" }],
  })
  async getFollowing(
    @Param("id", ParseUUIDPipe) id: string,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    return this.listFollowingUseCase.execute({
      userId: id,
      limit: query.limit ?? 20,
      offset: query.offset ?? 0,
      verifyUser: true,
    });
  }

  @GetAuth(":id/is-following", {
    summary: "Check if following a user",
    params: [{ name: "id", description: "Target user UUID" }],
  })
  async isFollowing(
    @Param("id", ParseUUIDPipe) followingId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.getFollowStatusUseCase.execute({ followerId: userId, followingId });
  }

  @PostAuth(":id/block", {
    summary: "Block a user",
    params: [{ name: "id", description: "Target user UUID" }],
    responseType: BlockResponse,
    errors: [
      { status: 404, description: "User not found" },
      { status: 409, description: "Already blocked" },
    ],
    httpCode: HttpStatus.OK,
  })
  async blockUser(
    @Param("id", ParseUUIDPipe) blockedId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.blockUserUseCase.execute({ blockerId: userId, blockedId });
  }

  @PatchAuth(":id/unblock", {
    summary: "Unblock a user",
    params: [{ name: "id", description: "Target user UUID" }],
    responseType: BlockResponse,
    errors: [{ status: 404, description: "Not blocked" }],
  })
  async unblockUser(
    @Param("id", ParseUUIDPipe) blockedId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.unblockUserUseCase.execute({ blockerId: userId, blockedId });
  }

  @GetAuth(":id/is-blocked", {
    summary: "Check if a user is blocked",
    params: [{ name: "id", description: "Target user UUID" }],
  })
  async isBlocked(
    @Param("id", ParseUUIDPipe) blockedId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.getBlockStatusUseCase.execute({ blockerId: userId, blockedId });
  }
}
