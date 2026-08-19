import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CreateBugReportDTO, BugReportResponse } from './dtos/bug-report.dto';
import { CreateBugReportUseCase } from './usecases/create-bug-report.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';

@ApiTags('Bug Reports')
@Controller('bug-reports')
export class BugReportController {
  constructor(private readonly createBugReportUseCase: CreateBugReportUseCase) {}

  @Post()
  @Authenticated({
    summary: 'Submit a bug report',
    bodyType: CreateBugReportDTO,
    responseType: BugReportResponse,
    responseStatus: 201,
    guards: [JwtAuthGuard],
  })
  async create(@CurrentUser() user: AuthUser, @Body() body: CreateBugReportDTO) {
    return this.createBugReportUseCase.execute({
      userId: user.userId,
      description: body.description,
      appVersion: body.appVersion,
      platform: body.platform,
      screenContext: body.screenContext,
    });
  }
}
