import { Body, Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PostAuth, CurrentUserId } from '@/shared/decorators';
import { CreateBugReportDTO, BugReportResponse } from './dtos/bug-report.dto';
import { CreateBugReportUseCase } from './usecases/create-bug-report.usecase';

@ApiTags('Bug Reports')
@Controller('bug-reports')
export class BugReportController {
  constructor(private readonly createBugReportUseCase: CreateBugReportUseCase) {}

  @PostAuth({
    summary: 'Submit a bug report',
    bodyType: CreateBugReportDTO,
    responseType: BugReportResponse,
    responseStatus: 201,
  })
  async create(@CurrentUserId() userId: string, @Body() body: CreateBugReportDTO) {
    return this.createBugReportUseCase.execute({
      userId,
      description: body.description,
      appVersion: body.appVersion,
      platform: body.platform,
      screenContext: body.screenContext,
    });
  }
}
