import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, UserNotFoundError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { AccountLifecycleRepository } from '../domain/repositories/account-lifecycle.repository';

@Injectable()
export class CancelAccountDeletionUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly accountLifecycleRepository: AccountLifecycleRepository,
  ) {}

  async execute(input: { userId: string }): Promise<Either<AppError, void>> {
    const userResult = await this.userRepository.findById(input.userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) return left(new UserNotFoundError());

    if (!userResult.value.deletionRequestedAt) {
      return left(new BadRequestError('Nenhuma exclusão de conta pendente'));
    }

    const cancelResult = await this.accountLifecycleRepository.cancelDeletion(input.userId);
    if (cancelResult.isLeft()) return left(cancelResult.value);

    return right(undefined);
  }
}
