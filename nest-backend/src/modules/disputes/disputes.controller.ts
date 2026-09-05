import { Controller, Body, Param, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, PatchAuth, PatchAdmin, CurrentUserId } from '@/shared/decorators';
import { OpenDisputeUseCase } from './usecases/open-dispute.usecase';
import { GetDisputeUseCase } from './usecases/get-dispute.usecase';
import { SubmitEvidenceUseCase } from './usecases/submit-evidence.usecase';
import { ResolveDisputeUseCase } from './usecases/resolve-dispute.usecase';
import { GetUserDisputesUseCase } from './usecases/get-user-disputes.usecase';
import { WithdrawDisputeUseCase } from './usecases/withdraw-dispute.usecase';
import { OpenDisputeDTO, ResolveDisputeDTO, OpenDisputeOutput } from './dtos/dispute.dto';
import { isLeft } from '@/shared/core/either';
import { Prisma } from '@prisma/client';

@ApiTags('Disputes')
@Controller('disputes')
export class DisputesController {
  constructor(
    private openDisputeUseCase: OpenDisputeUseCase,
    private getDisputeUseCase: GetDisputeUseCase,
    private submitEvidenceUseCase: SubmitEvidenceUseCase,
    private resolveDisputeUseCase: ResolveDisputeUseCase,
    private getUserDisputesUseCase: GetUserDisputesUseCase,
    private withdrawDisputeUseCase: WithdrawDisputeUseCase,
  ) {}

  @PostAuth({
    summary: 'Open a dispute',
    bodyType: OpenDisputeDTO,
    responseStatus: 201,
    responseType: OpenDisputeOutput,
    httpCode: HttpStatus.CREATED,
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async create(@CurrentUserId() userId: string, @Body() body: OpenDisputeDTO) {
    return this.openDisputeUseCase.execute({
      userId,
      orderId: body.orderId,
      reason: body.reason,
    });
  }

  @GetAuth('Get user disputes')
  async findAll(@CurrentUserId() userId: string) {
    const result = await this.getUserDisputesUseCase.execute(userId);
    if (isLeft(result)) return result;
    return { disputes: result.value };
  }

  @GetAuth(':id', {
    summary: 'Get dispute by ID',
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    const result = await this.getDisputeUseCase.execute(id, userId);
    if (isLeft(result)) return result;
    return { dispute: result.value };
  }

  @PostAuth(':id/evidence', {
    summary: 'Submit evidence',
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
    httpCode: HttpStatus.OK,
  })
  async submitEvidence(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string, @Body() body: { evidence: Prisma.InputJsonValue }) {
    return this.submitEvidenceUseCase.execute({
      disputeId: id,
      userId,
      evidence: body.evidence,
    });
  }

  @PatchAdmin(':id/resolve', {
    summary: 'Resolve a dispute',
    bodyType: ResolveDisputeDTO,
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
  })
  async resolve(@Param('id', ParseUUIDPipe) id: string, @Body() body: ResolveDisputeDTO) {
    return this.resolveDisputeUseCase.execute({
      disputeId: id,
      resolution: body.resolution,
      winner: body.winner,
    });
  }

  @PatchAuth(':id/withdraw', {
    summary: 'Withdraw a dispute',
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
    httpCode: HttpStatus.OK,
  })
  async withdraw(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.withdrawDisputeUseCase.execute({
      disputeId: id,
      userId,
    });
  }
}
