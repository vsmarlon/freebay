import { Module } from '@nestjs/common';
import { DisputesController } from './disputes.controller';
import { OpenDisputeUseCase, GetDisputeUseCase, SubmitEvidenceUseCase, ResolveDisputeUseCase, GetUserDisputesUseCase } from './usecases/dispute.usecase';
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
