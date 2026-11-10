import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { CommentDatabaseRepository } from '../data/repositories/comment-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';

@Injectable()
export class ApproveCommentUseCase {
  constructor(private readonly comments: CommentDatabaseRepository, private readonly notifications: NotificationService) {}

  async execute(commentId: string, ownerId: string): Promise<Either<AppError, void>> {
    const approved = await this.comments.approveHiddenComment(commentId, ownerId);
    if (approved.isLeft()) return left(approved.value);
    if (!approved.value.approved) return left(new NotFoundError('Comentário'));
    for (const notification of approved.value.notifications) this.notifications.deliverPersisted(notification.userId, notification.id, notification.type, notification.data);
    return right(undefined);
  }
}
