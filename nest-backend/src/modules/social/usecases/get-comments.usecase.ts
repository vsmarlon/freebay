import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CommentRepository } from '../domain/repositories/comment.repository';
import { CommentTree } from '../types/social.types';

@Injectable()
export class GetCommentsUseCase {
  constructor(private readonly commentRepository: CommentRepository) {}

  async execute(input: { postId: string; limit?: number; offset?: number }): Promise<Either<AppError, CommentTree[]>> {
    const result = await this.commentRepository.findAllByPostId(input.postId);
    if (isLeft(result)) return left(result.value);

    const nodes = new Map<string, CommentTree>();
    for (const comment of result.value) {
      nodes.set(comment.id, { ...comment, replies: [] });
    }

    const roots: CommentTree[] = [];
    for (const node of nodes.values()) {
      const parent = node.parentId ? nodes.get(node.parentId) : undefined;
      if (parent) {
        parent.replies.push(node);
      } else {
        roots.push(node);
      }
    }

    roots.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    const offset = input.offset ?? 0;
    const limit = input.limit ?? 20;
    return right(roots.slice(offset, offset + limit));
  }
}
