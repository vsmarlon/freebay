import { Module } from '@nestjs/common';
import { DisputesController } from './disputes.controller';
import { OpenDisputeUseCase } from './usecases/open-dispute.usecase';
import { GetDisputeUseCase } from './usecases/get-dispute.usecase';
import { SubmitEvidenceUseCase } from './usecases/submit-evidence.usecase';
import { ResolveDisputeUseCase } from './usecases/resolve-dispute.usecase';
import { GetUserDisputesUseCase } from './usecases/get-user-disputes.usecase';
import { WithdrawDisputeUseCase } from './usecases/withdraw-dispute.usecase';
import { DisputeRepository } from './domain/repositories/dispute.repository';
import { PrismaDisputeRepository } from './data/repositories/dispute-database.repository';
import { DisputeTransitionPolicy } from './services/dispute-transition.policy';
import { DisputeResolutionExecutionService } from './services/dispute-resolution-execution.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [PaymentsModule],
  controllers: [DisputesController],
  providers: [
    OpenDisputeUseCase,
    GetDisputeUseCase,
    SubmitEvidenceUseCase,
    ResolveDisputeUseCase,
    GetUserDisputesUseCase,
    WithdrawDisputeUseCase,
    PrismaDisputeRepository,
    { provide: DisputeRepository, useExisting: PrismaDisputeRepository },
    DisputeTransitionPolicy,
    DisputeResolutionExecutionService,
    PrismaService,
  ],
})
export class DisputesModule {}
