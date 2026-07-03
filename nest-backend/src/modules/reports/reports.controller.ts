import { Controller, Post, Get, Body, Param, UseGuards, HttpCode, HttpStatus, Query } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Roles } from '@/shared/decorators/roles.decorator';
import { RolesGuard } from '@/shared/guards/roles.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ReportsService } from './api/reports.service';
import { CreateReportDTO, ResolveReportDTO, GetReportsQueryDTO } from './dtos/report.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create a report',
    auth: true,
    bodyType: CreateReportDTO,
    responseStatus: 201,
  })
  async create(@CurrentUser() user: AuthUser, @Body() body: CreateReportDTO) {
    return this.reportsService.create(user.userId, body);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get reports',
    auth: true,
    queries: [
      { name: 'status', required: false, description: 'Filter by status' },
    ],
  })
  async findAll(@Query() query: GetReportsQueryDTO) {
    return this.reportsService.findAll(query);
  }

  @Post(':id/resolve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Resolve a report',
    auth: true,
    bodyType: ResolveReportDTO,
    params: [{ name: 'id', description: 'Report UUID' }],
    errors: [{ status: 404, description: 'Report not found' }],
  })
  async resolve(@Param('id') id: string, @Body() body: ResolveReportDTO) {
    return this.reportsService.resolve(id, body);
  }
}
