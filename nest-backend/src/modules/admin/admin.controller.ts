import { Body, Controller, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  CurrentUserId,
  DeleteAdmin,
  GetAdmin,
  PatchAdmin,
  PostAdmin,
} from '@/shared/decorators';
import { CursorQueryDTO } from '@/shared/dtos/pagination.dto';
import { ListReportsUseCase } from './usecases/list-reports.usecase';
import { ResolveReportUseCase } from './usecases/resolve-report.usecase';
import { SuspendUserUseCase } from './usecases/suspend-user.usecase';
import { RemoveContentUseCase } from './usecases/remove-content.usecase';
import { ListModerationActionsUseCase } from './usecases/list-moderation-actions.usecase';
import {
  AdminReportQueryDTO,
  ModerationReasonDTO,
  ResolveReportDTO,
  SuspendUserDTO,
} from './dtos/admin.dto';
import { AdminReportPageResponse, ModerationActionPageResponse } from './mappers/admin.mapper';

@ApiTags('Admin')
@Controller('admin')
export class AdminController {
  constructor(
    private readonly listReportsUseCase: ListReportsUseCase,
    private readonly resolveReportUseCase: ResolveReportUseCase,
    private readonly suspendUserUseCase: SuspendUserUseCase,
    private readonly removeContentUseCase: RemoveContentUseCase,
    private readonly listModerationActionsUseCase: ListModerationActionsUseCase,
  ) {}

  @GetAdmin('reports', {
    summary: 'List reports for moderation',
    description:
      'Cursor-paginated moderation queue including the reported target for every report type.',
    responseType: AdminReportPageResponse,
  })
  async listReports(@Query() query: AdminReportQueryDTO) {
    return this.listReportsUseCase.execute({
      status: query.status,
      cursor: query.cursor,
      limit: query.limit,
    });
  }

  @PatchAdmin('reports/:id/resolve', {
    summary: 'Resolve a report',
    description: 'Records the decision, who made it, and the note in the moderation audit trail.',
    bodyType: ResolveReportDTO,
    params: [{ name: 'id', description: 'Report UUID' }],
    errors: [
      { status: 404, description: 'Report not found' },
      { status: 409, description: 'Report was already reviewed' },
    ],
  })
  async resolveReport(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
    @Body() body: ResolveReportDTO,
  ) {
    return this.resolveReportUseCase.execute({
      reportId: id,
      adminId,
      status: body.status,
      note: body.note,
    });
  }

  @PostAdmin('users/:id/suspend', {
    summary: 'Suspend a user',
    description: 'Blocks access immediately by revoking every outstanding session.',
    bodyType: SuspendUserDTO,
    params: [{ name: 'id', description: 'User UUID' }],
    errors: [
      { status: 400, description: 'Cannot suspend your own account' },
      { status: 404, description: 'User not found' },
      { status: 409, description: 'User is already suspended' },
    ],
  })
  async suspendUser(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
    @Body() body: SuspendUserDTO,
  ) {
    return this.suspendUserUseCase.execute({
      targetUserId: id,
      adminId,
      suspend: true,
      reason: body.reason,
    });
  }

  @PatchAdmin('users/:id/unsuspend', {
    summary: 'Lift a user suspension',
    params: [{ name: 'id', description: 'User UUID' }],
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'User is not suspended' },
    ],
  })
  async unsuspendUser(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
  ) {
    return this.suspendUserUseCase.execute({ targetUserId: id, adminId, suspend: false });
  }

  @DeleteAdmin('products/:id', {
    summary: 'Take down a product',
    bodyType: ModerationReasonDTO,
    params: [{ name: 'id', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Product not found or already removed' }],
  })
  async removeProduct(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
    @Body() body: ModerationReasonDTO,
  ) {
    return this.removeContentUseCase.execute({
      targetType: 'PRODUCT',
      targetId: id,
      adminId,
      reason: body.reason,
    });
  }

  @DeleteAdmin('posts/:id', {
    summary: 'Take down a post',
    bodyType: ModerationReasonDTO,
    params: [{ name: 'id', description: 'Post UUID' }],
    errors: [{ status: 404, description: 'Post not found or already removed' }],
  })
  async removePost(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
    @Body() body: ModerationReasonDTO,
  ) {
    return this.removeContentUseCase.execute({
      targetType: 'POST',
      targetId: id,
      adminId,
      reason: body.reason,
    });
  }

  @DeleteAdmin('comments/:id', {
    summary: 'Take down a comment',
    bodyType: ModerationReasonDTO,
    params: [{ name: 'id', description: 'Comment UUID' }],
    errors: [{ status: 404, description: 'Comment not found or already removed' }],
  })
  async removeComment(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() adminId: string,
    @Body() body: ModerationReasonDTO,
  ) {
    return this.removeContentUseCase.execute({
      targetType: 'COMMENT',
      targetId: id,
      adminId,
      reason: body.reason,
    });
  }

  @GetAdmin('moderation-actions', {
    summary: 'List the moderation audit trail',
    responseType: ModerationActionPageResponse,
  })
  async listModerationActions(@Query() query: CursorQueryDTO) {
    return this.listModerationActionsUseCase.execute({
      cursor: query.cursor,
      limit: query.limit,
    });
  }
}
