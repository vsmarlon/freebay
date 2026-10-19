import { Injectable } from '@nestjs/common';
import { createHash, randomUUID } from 'node:crypto';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { QuoteDatabaseRepository } from '../data/repositories/quote-database.repository';
import { PostResponse } from '../types/social.types';

export interface CreateQuoteInput {
  userId: string;
  content: string;
  sourcePostId?: string;
  sourceCommentId?: string;
  mentionIds?: string[];
  clientRequestId?: string;
  image?: Express.Multer.File;
  imageBlurHash?: string;
}

@Injectable()
export class CreateQuoteUseCase {
  constructor(
    private readonly quoteRepository: QuoteDatabaseRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: CreateQuoteInput): Promise<Either<AppError, PostResponse>> {
    const content = input.content.trim();
    if (content.length < 1 || content.length > 1000 || Boolean(input.sourcePostId) === Boolean(input.sourceCommentId)) {
      return left(new BadRequestError('A quote deve conter texto e exatamente uma publicação ou resposta de origem'));
    }
    const mentionIds = [...new Set(input.mentionIds ?? [])].filter((id) => id !== input.userId).sort();
    const file = input.image;
    const imageHash = file ? createHash('sha256').update(file.buffer).digest('hex') : null;
    const digest = createHash('sha256').update(JSON.stringify({
      content,
      sourcePostId: input.sourcePostId ?? null,
      sourceCommentId: input.sourceCommentId ?? null,
      mentionIds,
      image: file ? { sha256: imageHash, mimeType: file.mimetype, size: file.size } : null,
    })).digest('hex');
    const result = await this.quoteRepository.create({
      userId: input.userId,
      content,
      sourcePostId: input.sourcePostId,
      sourceCommentId: input.sourceCommentId,
      mentionIds,
      requestId: input.clientRequestId ?? randomUUID(),
      digest,
      imageBlurHash: input.imageBlurHash,
      image: file && imageHash ? { buffer: file.buffer, mimeType: file.mimetype, size: file.size, sha256: imageHash } : undefined,
    });
    if (result.isLeft()) return left(result.value);
    for (const notification of result.value.notifications) {
      this.notificationService.deliverPersisted(notification.userId, notification.id, notification.type, notification.data);
    }
    return right(result.value.post);
  }
}
