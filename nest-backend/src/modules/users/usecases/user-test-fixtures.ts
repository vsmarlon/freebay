import { Either, right } from '@/shared/core/either';
import { UserResponse } from '../dtos/user-response.class';
import { UserRole } from '@prisma/client';

export const mockUser: UserResponse = {
  id: 'user-123',
  displayName: 'Test User',
  username: 'test_user',
  avatarUrl: 'https://example.com/avatar.jpg',
  bannerUrl: null,
  bio: 'Test bio',
  city: 'São Paulo',
  state: 'SP',
  isVerified: false,
  reputationScore: 4.5,
  totalReviews: 10,
  role: UserRole.USER,
  hasCpf: false,
  postsCount: 0,
  productsCount: 0,
  hasActiveStory: false,
  createdAt: new Date(),
};

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

export const rightCounts = () => right({
  postsCount: 0,
  productsCount: 0,
  hasActiveStory: false,
});
