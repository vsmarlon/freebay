import {
  Controller,
  Post,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  Headers,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Public } from '@/shared/decorators/public.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { CreatePixPaymentUseCase, ProcessWebhookUseCase } from './usecases/payment.usecase';
import { ProcessWebhookInput, CreatePixPaymentOutput } from './dtos/payment.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly createPixPaymentUseCase: CreatePixPaymentUseCase,
    private readonly processWebhookUseCase: ProcessWebhookUseCase,
  ) {}

  @Post('pix/:orderId')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Create PIX payment',
    description: 'Creates a PIX QR code for an order (rate limited: 5/min)',
    auth: true,
    responseStatus: 201,
    responseType: CreatePixPaymentOutput,
    params: [{ name: 'orderId', description: 'Order UUID' }],
    errors: [
      { status: 429, description: 'Too many requests' },
    ],
  })
  async createPixPayment(
    @Param('orderId') orderId: string,
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const result = await this.createPixPaymentUseCase.execute({
      orderId,
      userId: user.userId,
      idempotencyKey,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Post('webhook')
  @Public()
  @Throttle({ default: { limit: 60, ttl: 60000 } })
  @UseGuards(WebhookGuard)
  @HttpCode(HttpStatus.OK)
  @ApiDoc({
    summary: 'Payment webhook',
    description: 'Receives payment status updates from the PIX provider',
  })
  async handleWebhook(
    @Body() body: ProcessWebhookInput,
    @Headers('x-webhook-event') event?: string,
  ) {
    const result = await this.processWebhookUseCase.execute({
      event: event || body.event || 'charge.completed',
      data: body,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }
}
