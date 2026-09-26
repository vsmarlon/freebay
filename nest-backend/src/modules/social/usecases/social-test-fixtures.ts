import { Either } from '@/shared/core/either';
import {
  CreateCommentInput,
  CreatePostInput,
} from '../dtos/social.dto';

export const createPostInput = (
  overrides: Partial<CreatePostInput> = {},
): CreatePostInput => ({
  userId: 'user-123',
  content: 'Test content',
  type: 'REGULAR',
  ...overrides,
});

export const createCommentInput = (
  overrides: Partial<CreateCommentInput> = {},
): CreateCommentInput => ({
  userId: 'user-123',
  postId: 'post-123',
  content: 'Great post!',
  ...overrides,
});

export const expectRight = <T>(result: Either<unknown, T>): T => {
  expect(result.isRight()).toBe(true);
  if (result.isRight()) return result.value;
  throw new Error('Expected a right result');
};

export const expectLeft = <T>(result: Either<T, unknown>): T => {
  expect(result.isLeft()).toBe(true);
  if (result.isLeft()) return result.value;
  throw new Error('Expected a left result');
};
