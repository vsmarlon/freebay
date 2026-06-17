import { Controller, Post, Get, Body, Param, UseGuards, HttpCode, HttpStatus, Query } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Roles } from '@/shared/decorators/roles.decorator';
import { RolesGuard } from '@/shared/guards/roles.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CreateReportUseCase, GetReportsUseCase, ResolveReportUseCase } from './usecases/report.usecase';
import { CreateReportDTO, ResolveReportDTO } from './dtos/report.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  constructor(
    private createReportUseCase: CreateReportUseCase,
    private getReportsUseCase: GetReportsUseCase,
    private resolveReportUseCase: ResolveReportUseCase,
  ) {}

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
    const result = await this.createReportUseCase.execute({
      reporterId: user.userId,
      ...body,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
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
  async findAll(@Query('status') status?: string) {
    const result = await this.getReportsUseCase.execute(status);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { reports: result.value };
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
    const result = await this.resolveReportUseCase.execute({
      reportId: id,
      ...body,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
