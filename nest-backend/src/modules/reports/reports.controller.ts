import { Controller, Post, Get, Body, Param, UseGuards, HttpCode, HttpStatus, Query } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CreateReportUseCase, GetReportsUseCase, ResolveReportUseCase } from './usecases/report.usecase';
import { z } from 'zod';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

const _createReportSchema = z.object({
  targetType: z.enum(['USER', 'POST']),
  targetId: z.string().uuid(),
  reason: z.string(),
  description: z.string().optional(),
});

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
  async create(@CurrentUser() user: AuthUser, @Body() body: z.infer<typeof _createReportSchema>) {
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
  @UseGuards(JwtAuthGuard)
  async findAll(@Query('status') status?: string) {
    const result = await this.getReportsUseCase.execute(status);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { reports: result.value };
  }

  @Post(':id/resolve')
  @UseGuards(JwtAuthGuard)
  async resolve(@Param('id') id: string, @Body() body: { status: 'REVIEWED' | 'RESOLVED' | 'REJECTED'; adminNote?: string }) {
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
