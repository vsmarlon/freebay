import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { Request } from 'express';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { AbacatePayProvider } from '@/modules/payments/providers/abacatepay.provider';

@Injectable()
export class WebhookGuard implements CanActivate {
  private readonly logger = new Logger(WebhookGuard.name);

  constructor(
    private readonly redis: RedisService,
    private readonly abacatePay: AbacatePayProvider,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const signature = request.headers['x-webhook-signature'] as string;
    const webhookId = request.headers['x-webhook-id'] as string;

    // Replay protection
    if (webhookId) {
      const key = `webhook:${webhookId}`;
      if (await this.redis.exists(key)) {
        throw new UnauthorizedException('Webhook already processed');
      }
    }

    // Signature verification
    if (!this.abacatePay.verifyWebhook(signature, request.body)) {
      this.logger.warn('Invalid webhook signature');
      throw new UnauthorizedException('Invalid signature');
    }

    // Mark as processed
    if (webhookId) {
      await this.redis.add(`webhook:${webhookId}`, '1', 86400);
    }

    return true;
  }
}
