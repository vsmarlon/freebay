import { Injectable } from '@nestjs/common';
import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { BugReport } from '@prisma/client';
import { CreateBugReportInput } from '../dtos/bug-report.dto';
import { BugReportDatabaseRepository } from '../data/repositories/bug-report-database.repository';

@Injectable()
export class CreateBugReportUseCase {
  constructor(private readonly bugReportRepository: BugReportDatabaseRepository) {}

  async execute(input: CreateBugReportInput): Promise<Either<AppError, BugReport>> {
    return this.bugReportRepository.create(input);
  }
}
