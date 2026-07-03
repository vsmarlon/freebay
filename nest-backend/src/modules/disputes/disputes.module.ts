import { Module } from '@nestjs/common';
import { DisputesController } from './disputes.controller';
import { OpenDisputeUseCase } from './usecases/open-dispute.usecase';
import { GetDisputeUseCase } from './usecases/get-dispute.usecase';
import { SubmitEvidenceUseCase } from './usecases/submit-evidence.usecase';
import { ResolveDisputeUseCase } from './usecases/resolve-dispute.usecase';
import { GetUserDisputesUseCase } from './usecases/get-user-disputes.usecase';
import { WithdrawDisputeUseCase } from './usecases/withdraw-dispute.usecase';
import { PrismaDisputeRepository } from './repositories/dispute.repository';
import { DisputeTransitionPolicy } from './services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from './services/dispute-resolution-execution.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [DisputesController],
  providers: [
    OpenDisputeUseCase,
    GetDisputeUseCase,
    SubmitEvidenceUseCase,
    ResolveDisputeUseCase,
    GetUserDisputesUseCase,
    WithdrawDisputeUseCase,
    PrismaDisputeRepository,
    DisputeTransitionPolicy,
    DisputeResolutionExecutionService,
    PrismaService,
  ],
})
export class DisputesModule {}
