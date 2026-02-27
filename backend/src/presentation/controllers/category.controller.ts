import { FastifyRequest, FastifyReply } from 'fastify';
import {
  GetCategoriesUseCase,
  CreateCategoryUseCase,
} from '@/application/usecases/category.usecase';
import { ICategoryRepository } from '@/domain/repositories';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { createCategorySchema } from '@/presentation/dtos';

export class CategoryController {
  private getCategoriesUseCase: GetCategoriesUseCase;
  private createCategoryUseCase: CreateCategoryUseCase;

  constructor(categoryRepository: ICategoryRepository) {
    this.getCategoriesUseCase = new GetCategoriesUseCase(categoryRepository);
    this.createCategoryUseCase = new CreateCategoryUseCase(categoryRepository);
  }

  async getCategories(_request: FastifyRequest, reply: FastifyReply) {
    const result = await this.getCategoriesUseCase.execute();

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async createCategory(request: FastifyRequest, reply: FastifyReply) {
    const parsed = createCategorySchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const result = await this.createCategoryUseCase.execute(parsed.data);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.code(201).send(apiSuccess(result.value));
  }
}
