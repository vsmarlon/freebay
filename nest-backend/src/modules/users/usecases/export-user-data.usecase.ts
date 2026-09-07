import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UserNotFoundError } from '@/shared/core/errors';
import { AccountLifecycleDatabaseRepository } from '../data/repositories/account-lifecycle-database.repository';
import { UserDataExport } from '../types/account.types';

@Injectable()
export class ExportUserDataUseCase {
  constructor(private readonly accountLifecycleRepository: AccountLifecycleDatabaseRepository) {}

  async execute(input: { userId: string }): Promise<Either<AppError, UserDataExport>> {
    const exportResult = await this.accountLifecycleRepository.exportData(input.userId);
    if (exportResult.isLeft()) return left(exportResult.value);
    if (!exportResult.value) return left(new UserNotFoundError());

    return right(exportResult.value);
  }
}
