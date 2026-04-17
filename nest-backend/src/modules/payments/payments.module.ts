import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PaymentsController } from './payments.controller';
import { CreatePixPaymentUseCase, ProcessWebhookUseCase } from './usecases/payment.usecase';
import { AbacatePayProvider } from './providers/abacatepay.provider';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaOrderRepository } from '../orders/repositories/order.repository';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { RedisService } from '@/shared/infra/redis/redis.service';

@Module({
  imports: [ConfigModule],
  controllers: [PaymentsController],
  providers: [
    CreatePixPaymentUseCase,
    ProcessWebhookUseCase,
    AbacatePayProvider,
    PrismaService,
    PrismaOrderRepository,
    WebhookGuard,
    RedisService,
  ],
  exports: [AbacatePayProvider, CreatePixPaymentUseCase],
})
export class PaymentsModule {}
