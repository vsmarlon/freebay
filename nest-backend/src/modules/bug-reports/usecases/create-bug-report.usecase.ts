import { Injectable } from '@nestjs/common';
import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { BugReport } from '@prisma/client';
import { CreateBugReportInput } from '../dtos/bug-report.dto';
import { BugReportRepository } from '../domain/repositories/bug-report.repository';

@Injectable()
export class CreateBugReportUseCase {
  constructor(private readonly bugReportRepository: BugReportRepository) {}

  async execute(input: CreateBugReportInput): Promise<Either<AppError, BugReport>> {
    return this.bugReportRepository.create(input);
  }
}
