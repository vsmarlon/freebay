import { Controller, Get, Post, Body, Param, UseGuards, HttpCode, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { OpenDisputeUseCase, GetDisputeUseCase, SubmitEvidenceUseCase, ResolveDisputeUseCase, GetUserDisputesUseCase } from './usecases/dispute.usecase';
import { OpenDisputeInput, SubmitEvidenceInput } from './dtos/dispute.dto';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Controller('disputes')
@UseGuards(JwtAuthGuard)
export class DisputesController {
  constructor(
    private openDisputeUseCase: OpenDisputeUseCase,
    private getDisputeUseCase: GetDisputeUseCase,
    private submitEvidenceUseCase: SubmitEvidenceUseCase,
    private resolveDisputeUseCase: ResolveDisputeUseCase,
    private getUserDisputesUseCase: GetUserDisputesUseCase,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@CurrentUser() user: AuthUser, @Body() body: OpenDisputeInput) {
    const result = await this.openDisputeUseCase.execute({
      userId: user.userId,
      orderId: body.orderId,
      reason: body.reason,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get()
  async findAll(@CurrentUser() user: AuthUser) {
    const result = await this.getUserDisputesUseCase.execute(user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { disputes: result.value };
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.getDisputeUseCase.execute(id, user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { dispute: result.value };
  }

  @Post(':id/evidence')
  @HttpCode(HttpStatus.OK)
  async submitEvidence(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser, @Body() body: SubmitEvidenceInput) {
    const result = await this.submitEvidenceUseCase.execute({
      disputeId: id,
      userId: user.userId,
      evidence: body.evidence,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post(':id/resolve')
  async resolve(@Param('id', ParseUUIDPipe) id: string, @Body() body: { resolution: string; winner: 'BUYER' | 'SELLER' }) {
    const result = await this.resolveDisputeUseCase.execute({
      disputeId: id,
      resolution: body.resolution,
      winner: body.winner,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
