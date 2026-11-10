import { Controller, Body, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth, CurrentUserId } from '@/shared/decorators';
import { CreateReportUseCase } from './usecases/create-report.usecase';
import { unwrap } from '@/shared/http/unwrap';
import { CreateReportDTO } from './dtos/report.dto';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  constructor(private readonly createReportUseCase: CreateReportUseCase) {}

  @PostAuth({
    summary: 'Create a report',
    bodyType: CreateReportDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  async create(@CurrentUserId() userId: string, @Body() body: CreateReportDTO) {
    return unwrap(await this.createReportUseCase.execute({ reporterId: userId, ...body }));
  }
}
