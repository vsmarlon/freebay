import { Injectable } from '@nestjs/common';
import { isLeft } from '@/shared/core/either';
import { CreateReportUseCase } from '../usecases/create-report.usecase';
import { GetReportsUseCase } from '../usecases/get-reports.usecase';
import { ResolveReportUseCase } from '../usecases/resolve-report.usecase';
import { CreateReportDTO, GetReportsQueryDTO, ResolveReportDTO } from '../dtos/report.dto';

@Injectable()
export class ReportsService {
  constructor(
    private readonly createReportUseCase: CreateReportUseCase,
    private readonly getReportsUseCase: GetReportsUseCase,
    private readonly resolveReportUseCase: ResolveReportUseCase,
  ) {}

  async create(reporterId: string, body: CreateReportDTO) {
    const result = await this.createReportUseCase.execute({
      reporterId,
      ...body,
    });
    if (isLeft(result)) {
      throw result.value;
    }
    return result.value;
  }

  async findAll(query: GetReportsQueryDTO) {
    const result = await this.getReportsUseCase.execute(query.status);
    if (isLeft(result)) {
      throw result.value;
    }
    return { reports: result.value };
  }

  async resolve(id: string, body: ResolveReportDTO) {
    const result = await this.resolveReportUseCase.execute({
      reportId: id,
      ...body,
    });
    if (isLeft(result)) {
      throw result.value;
    }
    return result.value;
  }
}
