import { Controller, Get, Post, Body, Param, UseGuards, HttpCode, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Roles } from '@/shared/decorators/roles.decorator';
import { RolesGuard } from '@/shared/guards/roles.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { OpenDisputeUseCase, GetDisputeUseCase, SubmitEvidenceUseCase, ResolveDisputeUseCase, GetUserDisputesUseCase } from './usecases/dispute.usecase';
import { OpenDisputeDTO, ResolveDisputeDTO, OpenDisputeOutput } from './dtos/dispute.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { Prisma } from '@prisma/client';

@ApiTags('Disputes')
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Open a dispute',
    auth: true,
    bodyType: OpenDisputeDTO,
    responseStatus: 201,
    responseType: OpenDisputeOutput,
    errors: [{ status: 404, description: 'Order not found' }],
  })
  async create(@CurrentUser() user: AuthUser, @Body() body: OpenDisputeDTO) {
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get user disputes',
    auth: true,
  })
  async findAll(@CurrentUser() user: AuthUser) {
    const result = await this.getUserDisputesUseCase.execute(user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { disputes: result.value };
  }

  @Get(':id')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get dispute by ID',
    auth: true,
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
  })
  async findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
    const result = await this.getDisputeUseCase.execute(id, user.userId);

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { dispute: result.value };
  }

  @Post(':id/evidence')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Submit evidence',
    auth: true,
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
  })
  async submitEvidence(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser, @Body() body: { evidence: Prisma.InputJsonValue }) {
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
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Resolve a dispute',
    auth: true,
    bodyType: ResolveDisputeDTO,
    params: [{ name: 'id', description: 'Dispute UUID' }],
    errors: [{ status: 404, description: 'Dispute not found' }],
  })
  async resolve(@Param('id', ParseUUIDPipe) id: string, @Body() body: ResolveDisputeDTO) {
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
