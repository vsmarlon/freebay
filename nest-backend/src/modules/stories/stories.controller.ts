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
import { deleteUpload, saveUpload } from "@/shared/utils/file.utils";
import { StoriesService } from "./stories.service";
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from "@/shared/decorators";
import { left } from "@/shared/core/either";
import { BadRequestError } from "@/shared/core/errors";
import { validateMediaFile } from "@/shared/utils/image-upload.utils";
import {
  CreateStoryMultipartDTO,
  SaveStoryHighlightDTO,
  parseStoryTextBlocks,
  STORY_CAPTION_MAX_LENGTH,
  STORY_TEXT_BLOCKS_PAYLOAD_MAX_LENGTH,
} from "./dtos/stories.dto";
import { MAX_MEDIA_SIZE } from "@/shared/utils/image-upload.utils";
import { Prisma, StoryMediaType } from "@prisma/client";

@ApiTags("Stories")
@Controller("stories")
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @GetAuth('archive', { summary: 'List my stories, including expired stories' })
  async getArchive(@CurrentUserId() userId: string) {
    return this.storiesService.getArchive(userId);
  }

  @GetAuth('highlights/user/:userId', { summary: 'List public highlights for a user' })
  async getHighlights(@Param('userId', ParseUUIDPipe) userId: string, @CurrentUserId() viewerId: string) {
    return this.storiesService.getHighlights(userId, viewerId);
  }

  @GetAuth('highlights/:id', { summary: 'View a public highlight' })
  async getHighlight(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() viewerId: string) {
    return this.storiesService.getHighlight(id, viewerId);
  }

  @PostAuth('highlights', { summary: 'Create a story highlight', bodyType: SaveStoryHighlightDTO, responseStatus: 201, httpCode: HttpStatus.CREATED })
  async createHighlight(@CurrentUserId() userId: string, @Body() body: SaveStoryHighlightDTO) {
    return this.storiesService.saveHighlight({ userId, ...body });
  }

  @PatchAuth('highlights/:id', { summary: 'Edit a story highlight', bodyType: SaveStoryHighlightDTO })
  async updateHighlight(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string, @Body() body: SaveStoryHighlightDTO) {
    return this.storiesService.saveHighlight({ id, userId, ...body });
  }

  @PatchAuth('highlights/:id/delete', { summary: 'Delete a story highlight' })
  async deleteHighlight(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.storiesService.deleteHighlight(id, userId);
  }

  @GetAuth({ summary: "List active stories for explore/feed" })
  async getFeed(@CurrentUserId() userId: string) {
    return this.storiesService.getStories(userId);
  }

  @GetAuth("user/:userId", {
    summary: "List active stories for a specific user",
    params: [{ name: "userId", description: "User UUID" }],
  })
  async getUserStories(@Param("userId", ParseUUIDPipe) userId: string, @CurrentUserId() viewerId: string) {
    return this.storiesService.getUserStories(userId, viewerId);
  }

  @PostAuth({
    summary: "Create a story",
    description: "Uploads an image or video that will be available for 24h",
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  @UseInterceptors(
    FileInterceptor("image", {
      storage: memoryStorage(),
      limits: { fileSize: MAX_MEDIA_SIZE },
    }),
  )
  async createStory(
    @CurrentUserId() userId: string,
    @UploadedFile() file?: Express.Multer.File,
    @Body() body?: CreateStoryMultipartDTO,
  ) {
    if (!file) return left(new BadRequestError("Imagem é obrigatória"));
    if (
      !file.mimetype.startsWith("image/") &&
      !file.mimetype.startsWith("video/")
    ) {
      return left(new BadRequestError("Stories aceitam apenas imagens ou vídeos"));
    }
    const mimeError = validateMediaFile(file);
    if (mimeError) return left(new BadRequestError(mimeError));
    if (typeof body?.caption === "string" && body.caption.length > STORY_CAPTION_MAX_LENGTH) {
      return left(
        new BadRequestError("A legenda deve ter no máximo 500 caracteres"),
      );
    }
    if (
      typeof body?.textBlocks === "string" &&
      body.textBlocks.length > STORY_TEXT_BLOCKS_PAYLOAD_MAX_LENGTH
    ) {
      return left(
        new BadRequestError("textBlocks excede o tamanho máximo permitido"),
      );
    }
    const textBlocks = parseStoryTextBlocks(body?.textBlocks);
    if ("error" in textBlocks)
      return left(new BadRequestError(textBlocks.error));
    const textBlocksForPersistence: Prisma.InputJsonValue =
      textBlocks.value.map((block): Prisma.InputJsonObject => ({ ...block }));

    const imageUrl = saveUpload(file, "story");
    const result = await this.storiesService.createStory({
      userId,
      imageUrl,
      mediaType: file.mimetype.startsWith("video/") ? StoryMediaType.VIDEO : StoryMediaType.IMAGE,
      audience: body?.audience,
      caption: typeof body?.caption === "string" ? body.caption : undefined,
      textBlocks: textBlocksForPersistence,
    });
    if (result.isLeft()) deleteUpload(imageUrl);
    return result;
  }

  @PatchAuth(":id/delete", {
    summary: "Soft-delete a story",
    params: [{ name: "id", description: "Story UUID" }],
  })
  async deleteStory(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
  ) {
    return this.storiesService.deleteStory({ storyId: id, userId });
  }

  @PostAuth(":id/view", {
    summary: "View a story",
    description: "Marks a story as viewed by the current user",
    params: [{ name: "id", description: "Story UUID" }],
  })
  async viewStory(
    @Param("id", ParseUUIDPipe) id: string,
    @CurrentUserId() viewerId: string,
  ) {
    return this.storiesService.viewStory({
      storyId: id,
      viewerId: viewerId || "",
    });
  }
}
