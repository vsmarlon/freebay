import { FastifyRequest, FastifyReply } from 'fastify';
import {
  CreateProductUseCase,
  SearchProductsUseCase,
  GetProductUseCase,
  DeleteProductUseCase,
} from '@/application/usecases/products';
import { IProductRepository } from '@/domain/repositories';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { createProductSchema } from '@/presentation/dtos';

export class ProductController {
  private createProductUseCase: CreateProductUseCase;
  private searchProductsUseCase: SearchProductsUseCase;
  private getProductUseCase: GetProductUseCase;
  private deleteProductUseCase: DeleteProductUseCase;

  constructor(private productRepository: IProductRepository) {
    this.createProductUseCase = new CreateProductUseCase(productRepository);
    this.searchProductsUseCase = new SearchProductsUseCase(productRepository);
    this.getProductUseCase = new GetProductUseCase(productRepository);
    this.deleteProductUseCase = new DeleteProductUseCase(productRepository);
  }

  async create(request: FastifyRequest, reply: FastifyReply) {
    const parsed = createProductSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const userId = request.user.userId;
    const result = await this.createProductUseCase.execute({
      ...parsed.data,
      sellerId: userId!,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.code(201).send(apiSuccess(result.value));
  }

  async list(
    request: FastifyRequest<{
      Querystring: {
        cursor?: string;
        limit?: string;
        search?: string;
        category?: string;
        minPrice?: string;
        maxPrice?: string;
      };
    }>,
    reply: FastifyReply,
  ) {
    const { cursor, limit, search, category, minPrice, maxPrice } = request.query;

    const result = await this.searchProductsUseCase.execute({
      cursor,
      limit: limit ? parseInt(limit, 10) : 20,
      search,
      category,
      minPrice: minPrice ? parseInt(minPrice, 10) : undefined,
      maxPrice: maxPrice ? parseInt(maxPrice, 10) : undefined,
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async getById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const { id } = request.params;
    const result = await this.getProductUseCase.execute(id);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async delete(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const { id } = request.params;
    const result = await this.deleteProductUseCase.execute(id);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess({ deleted: true }));
  }
}
