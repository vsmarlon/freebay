import { Controller, Body, Param, HttpStatus, Query, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth, GetAdmin, PatchAdmin, CurrentUserId } from '@/shared/decorators';
import { ReportsService } from './reports.service';
import { CreateReportDTO, ResolveReportDTO, GetReportsQueryDTO } from './dtos/report.dto';

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

  @GetAdmin({
    summary: 'Get reports',
    queries: [
      { name: 'status', required: false, description: 'Filter by status' },
    ],
  })
  async findAll(@Query() query: GetReportsQueryDTO) {
    return this.reportsService.findAll(query);
  }

  @PatchAdmin(':id/resolve', {
    summary: 'Resolve a report',
    bodyType: ResolveReportDTO,
    params: [{ name: 'id', description: 'Report UUID' }],
    errors: [{ status: 404, description: 'Report not found' }],
  })
  async resolve(@Param('id', ParseUUIDPipe) id: string, @Body() body: ResolveReportDTO) {
    return this.reportsService.resolve(id, body);
  }
}
