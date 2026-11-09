import { Injectable } from '@nestjs/common';
import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ShareDatabaseRepository } from '../data/repositories/share-database.repository';
import { MutationState } from '../types/social.types';

@Injectable()
export class UnsharePostUseCase {
  constructor(private readonly shareRepository: ShareDatabaseRepository) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, MutationState>> {
    return this.shareRepository.setPostShare(input.userId, input.postId, false);
  }
}
