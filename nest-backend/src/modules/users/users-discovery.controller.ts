import { Controller, Query } from "@nestjs/common";
import { ApiTags } from "@nestjs/swagger";
import {
  SearchUsersUseCase,
  GetSuggestionsUseCase,
} from "./usecases";
import { GetAuth, CurrentUserId } from "@/shared/decorators";
import {
  OffsetPaginationQueryDTO,
  UserSearchQueryDTO,
  SuggestionsQueryDTO,
} from "./dtos/user.dto";
import { toUserBrief } from "./dtos/user-response.class";
import { PrismaBlockRepository } from "./data/repositories/block-database.repository";

@ApiTags("Users")
@Controller("users")
export class UsersDiscoveryController {
  constructor(
    private readonly blockRepository: PrismaBlockRepository,
    private readonly searchUsersUseCase: SearchUsersUseCase,
    private readonly getSuggestionsUseCase: GetSuggestionsUseCase,
  ) {}

  @GetAuth("blocked", {
    summary: "Get blocked users",
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
  })
  async getBlockedUsers(
    @CurrentUserId() userId: string,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const result = await this.blockRepository.getBlockedUsers(
      userId,
      parsedLimit,
      parsedOffset,
    );
    if (result.isLeft()) return result;

    return {
      users: result.value.map(toUserBrief),
      limit: parsedLimit,
      offset: parsedOffset,
    };
  }

  @GetAuth("search", {
    summary: "Search users",
    queries: [
      { name: "q", required: false, description: "Search query" },
      {
        name: "offset",
        required: false,
        description: "Pagination offset (default 0)",
      },
      {
        name: "limit",
        required: false,
        description: "Results per page (default 20)",
      },
    ],
  })
  async searchUsers(
    @CurrentUserId() userId: string,
    @Query() query: UserSearchQueryDTO,
  ) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const searchResult = await this.searchUsersUseCase.execute({
      query: query.q || "",
      limit: parsedLimit,
      offset: parsedOffset,
      viewerId: userId,
    });
    if (searchResult.isLeft()) return searchResult;
    const users = searchResult.value;

    return {
      users,
      hasMore: users.length === parsedLimit,
      nextOffset:
        users.length === parsedLimit ? parsedOffset + parsedLimit : null,
    };
  }

  @GetAuth("suggestions", {
    summary: "Get user suggestions",
    queries: [
      {
        name: "limit",
        required: false,
        description: "Number of suggestions (default 10)",
      },
    ],
  })
  async getSuggestions(
    @CurrentUserId() userId: string,
    @Query() query: SuggestionsQueryDTO,
  ) {
    const suggestionsResult = await this.getSuggestionsUseCase.execute({
      userId,
      limit: query.limit ?? 10,
    });
    if (suggestionsResult.isLeft()) return suggestionsResult;
    return { users: suggestionsResult.value };
  }
}
