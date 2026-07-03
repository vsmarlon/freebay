import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CreateBugReportDTO, BugReportResponse } from './dtos/bug-report.dto';
import { CreateBugReportUseCase } from './usecases/create-bug-report.usecase';
import { toBugReportResponse } from './mappers/bug-report.mapper';

@ApiTags('Bug Reports')
@Controller('bug-reports')
export class BugReportController {
  constructor(private readonly createBugReportUseCase: CreateBugReportUseCase) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Submit a bug report',
    auth: true,
    bodyType: CreateBugReportDTO,
    responseType: BugReportResponse,
    responseStatus: 201,
  })
  async create(@CurrentUser() user: AuthUser, @Body() body: CreateBugReportDTO) {
    const result = await this.createBugReportUseCase.execute({
      userId: user.userId,
      description: body.description,
      appVersion: body.appVersion,
      platform: body.platform,
      screenContext: body.screenContext,
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return toBugReportResponse(result.value);
  }
}
