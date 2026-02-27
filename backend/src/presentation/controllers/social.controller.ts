import { FastifyRequest, FastifyReply } from 'fastify';
import {
  CreatePostUseCase,
  GetFeedUseCase,
  GetPostByIdUseCase,
  CreateStoryUseCase,
  GetStoriesUseCase,
  DeleteStoryUseCase,
  ViewStoryUseCase,
  GetUserStoriesUseCase,
  LikePostUseCase,
  UnlikePostUseCase,
  CreateCommentUseCase,
  GetCommentsUseCase,
} from '@/application/usecases/social';
import {
  IPostRepository,
  IStoryRepository,
  ILikeRepository,
  ICommentRepository,
} from '@/domain/repositories';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { FileStorageService } from '@/infra/storage/file-storage.service';
import { createCommentSchema } from '@/presentation/dtos';

export class SocialController {
  private createPostUseCase: CreatePostUseCase;
  private getFeedUseCase: GetFeedUseCase;
  private getPostByIdUseCase: GetPostByIdUseCase;
  private createStoryUseCase: CreateStoryUseCase;
  private getStoriesUseCase: GetStoriesUseCase;
  private deleteStoryUseCase: DeleteStoryUseCase;
  private viewStoryUseCase: ViewStoryUseCase;
  private getUserStoriesUseCase: GetUserStoriesUseCase;
  private likePostUseCase: LikePostUseCase;
  private unlikePostUseCase: UnlikePostUseCase;
  private createCommentUseCase: CreateCommentUseCase;
  private getCommentsUseCase: GetCommentsUseCase;
  private fileStorageService: FileStorageService;

  constructor(
    postRepository: IPostRepository,
    storyRepository: IStoryRepository,
    likeRepository: ILikeRepository,
    commentRepository: ICommentRepository,
    fileStorageService?: FileStorageService,
  ) {
    this.createPostUseCase = new CreatePostUseCase(postRepository);
    this.getFeedUseCase = new GetFeedUseCase(postRepository);
    this.getPostByIdUseCase = new GetPostByIdUseCase(postRepository);

    this.createStoryUseCase = new CreateStoryUseCase(storyRepository);
    this.getStoriesUseCase = new GetStoriesUseCase(storyRepository);
    this.deleteStoryUseCase = new DeleteStoryUseCase(storyRepository);
    this.viewStoryUseCase = new ViewStoryUseCase(storyRepository);
    this.getUserStoriesUseCase = new GetUserStoriesUseCase(storyRepository);

    this.likePostUseCase = new LikePostUseCase(likeRepository, postRepository);
    this.unlikePostUseCase = new UnlikePostUseCase(likeRepository, postRepository);
    this.createCommentUseCase = new CreateCommentUseCase(commentRepository, postRepository);
    this.getCommentsUseCase = new GetCommentsUseCase(commentRepository);

    this.fileStorageService = fileStorageService ?? new FileStorageService();
  }

  async createPost(
    request: FastifyRequest<{
      Body: { content?: string; imageUrl?: string; type: 'PRODUCT' | 'REGULAR' };
    }>,
    reply: FastifyReply,
  ) {
    const userId = request.user.userId!;
    const { content, imageUrl, type } = request.body;

    const result = await this.createPostUseCase.execute({
      content: content ?? null,
      imageUrl: imageUrl ?? null,
      type,
      userId,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.code(201).send(apiSuccess(result.value));
  }

  async getFeed(
    request: FastifyRequest<{ Querystring: { cursor?: string; limit?: string } }>,
    reply: FastifyReply,
  ) {
    const userId = request.user?.userId;
    const { cursor, limit } = request.query;

    const result = await this.getFeedUseCase.execute({
      userId: userId!,
      cursor,
      limit: limit ? parseInt(limit, 10) : 20,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async getPostById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const { id } = request.params;

    const result = await this.getPostByIdUseCase.execute(id);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async like(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const userId = request.user.userId!; // Checked by requireNonGuest
    const { id } = request.params;

    const result = await this.likePostUseCase.execute(userId, id);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async unlike(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const userId = request.user.userId!; // Checked by requireNonGuest
    const { id } = request.params;

    const result = await this.unlikePostUseCase.execute(userId, id);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async comment(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const parsed = createCommentSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const userId = request.user.userId!; // Checked by requireNonGuest
    const { id } = request.params;

    const result = await this.createCommentUseCase.execute({
      content: parsed.data.content,
      userId,
      postId: id,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.code(201).send(apiSuccess(result.value));
  }

  async getComments(
    request: FastifyRequest<{
      Params: { id: string };
      Querystring: { cursor?: string; limit?: string };
    }>,
    reply: FastifyReply,
  ) {
    const { id } = request.params;
    const { cursor, limit } = request.query;

    const result = await this.getCommentsUseCase.execute(id, {
      cursor,
      limit: limit ? parseInt(limit, 10) : 20,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async getStories(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user?.userId ?? '';

    const result = await this.getStoriesUseCase.execute(userId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async createStory(
    request: FastifyRequest<{ Body: { imageBase64: string } }>,
    reply: FastifyReply,
  ) {
    const userId = request.user.userId!; // Checked by requireNonGuest
    const { imageBase64 } = request.body;

    if (!imageBase64) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', 'Imagem é obrigatória'));
    }

    try {
      const imageUrl = await this.fileStorageService.saveBase64Image(
        imageBase64,
        `story_${userId}`,
      );
      const result = await this.createStoryUseCase.execute(userId, imageUrl);

      if (isLeft(result)) {
        return reply
          .code(result.value.statusCode)
          .send(apiError(result.value.code, result.value.message));
      }

      return reply.code(201).send(apiSuccess(result.value));
    } catch {
      return reply.code(500).send(apiError('UPLOAD_ERROR', 'Erro ao fazer upload da imagem'));
    }
  }

  async deleteStory(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const userId = request.user.userId!; // Checked by requireNonGuest
    const { id } = request.params;

    const result = await this.deleteStoryUseCase.execute(id, userId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess({ deleted: true }));
  }

  async viewStory(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const viewerId = request.user?.userId ?? '';
    const { id } = request.params;

    const result = await this.viewStoryUseCase.execute(id, viewerId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess({ viewed: true }));
  }

  async getUserStories(
    request: FastifyRequest<{ Params: { userId: string } }>,
    reply: FastifyReply,
  ) {
    const viewerId = request.user?.userId ?? '';
    const { userId } = request.params;

    const result = await this.getUserStoriesUseCase.execute(userId, viewerId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }
}
