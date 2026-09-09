import { Controller, Body, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth, CurrentUserId } from '@/shared/decorators';
import { ReportsService } from './reports.service';
import { CreateReportDTO } from './dtos/report.dto';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @PostAuth({
    summary: 'Create a report',
    bodyType: CreateReportDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  async create(@CurrentUserId() userId: string, @Body() body: CreateReportDTO) {
    return this.reportsService.create(userId, body);
  }
}
