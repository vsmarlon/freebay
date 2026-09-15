import { Injectable } from '@nestjs/common';
import { CreateReportUseCase } from './usecases/create-report.usecase';
import { CreateReportDTO } from './dtos/report.dto';

@Injectable()
export class ReportsService {
  constructor(private readonly createReportUseCase: CreateReportUseCase) {}

  async create(reporterId: string, body: CreateReportDTO) {
    const result = await this.createReportUseCase.execute({
      reporterId,
      ...body,
    });
    if (result.isLeft()) {
      throw result.value;
    }
    return result.value;
  }
}
