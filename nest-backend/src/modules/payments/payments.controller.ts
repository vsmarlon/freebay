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
  BadRequestException,
} from '@nestjs/common';
import { Throttle, SkipThrottle } from '@nestjs/throttler';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { Public } from '@/shared/decorators/public.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { CreatePixPaymentUseCase, ProcessWebhookUseCase } from './usecases/payment.usecase';
import { createPixPaymentSchema, CreatePixPaymentDTO, ProcessWebhookInput } from './dtos/payment.dto';

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
  async createPixPayment(
    @Param('orderId') orderId: string,
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(createPixPaymentSchema)) body: CreatePixPaymentDTO,
    @Headers('idempotency-key') idempotencyKey?: string,
  ) {
    const result = await this.createPixPaymentUseCase.execute({
      orderId,
      userId: user.userId,
      idempotencyKey,
      ...body,
    });

    if (result.isLeft()) {
      throw new BadRequestException(result.value.message);
    }

    return { success: true, data: result.value };
  }

  @Post('webhook')
  @Public()
  @SkipThrottle()
  @UseGuards(WebhookGuard)
  @HttpCode(HttpStatus.OK)
  async handleWebhook(
    @Body() body: ProcessWebhookInput,
    @Headers('x-webhook-event') event?: string,
  ) {
    const result = await this.processWebhookUseCase.execute({
      event: event || body.event || 'charge.completed',
      data: body,
    });

    if (result.isLeft()) {
      return { success: false, error: result.value.message };
    }

    return { success: true, data: result.value };
  }
}
