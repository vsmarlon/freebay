import { Module } from '@nestjs/common';
import { DisputesController } from './disputes.controller';
import { OpenDisputeUseCase } from './usecases/open-dispute.usecase';
import { GetDisputeUseCase } from './usecases/get-dispute.usecase';
import { SubmitEvidenceUseCase } from './usecases/submit-evidence.usecase';
import { ResolveDisputeUseCase } from './usecases/resolve-dispute.usecase';
import { GetUserDisputesUseCase } from './usecases/get-user-disputes.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [DisputesController],
  providers: [
    OpenDisputeUseCase,
    GetDisputeUseCase,
    SubmitEvidenceUseCase,
    ResolveDisputeUseCase,
    GetUserDisputesUseCase,
    PrismaService,
  ],
})
export class DisputesModule {}
