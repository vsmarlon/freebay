import { Test, TestingModule } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';
import { CommentUseCase } from './comment.usecase';

describe('CommentUseCase', () => {
  let useCase: CommentUseCase;
  let mockCommentRepo: { createWithCount: jest.Mock };

  beforeEach(async () => {
    mockCommentRepo = { createWithCount: jest.fn() };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentUseCase,
        { provide: PrismaCommentRepository, useValue: mockCommentRepo },
        { provide: NotificationService, useValue: { notifyMention: jest.fn() } },
      ],
    }).compile();

    useCase = module.get(CommentUseCase);
    mockCommentRepo.createWithCount.mockResolvedValue(
      right({ id: 'comment-1', createdAt: new Date() }),
    );
  });

  it('increments the post count exactly once for a root comment', async () => {
    const result = await useCase.execute({ postId: 'post-1', userId: 'user-1', content: 'root' });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.createWithCount).toHaveBeenCalledTimes(1);
  });

  it('increments the post count exactly once for a reply', async () => {
    const result = await useCase.execute({
      postId: 'post-1',
      userId: 'user-1',
      content: 'reply',
      parentId: 'comment-0',
    });

    expect(result.isRight()).toBe(true);
    expect(mockCommentRepo.createWithCount).toHaveBeenCalledTimes(1);
  });
});
