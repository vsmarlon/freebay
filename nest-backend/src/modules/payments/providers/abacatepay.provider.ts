import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PixChargeRequest, PixChargeResponse } from './abacatepay.types';

@Injectable()
export class AbacatePayProvider {
  private readonly logger = new Logger(AbacatePayProvider.name);
  private readonly apiKey: string;
  private readonly webhookSecret: string;
  private readonly baseUrl = 'https://api.abacatepay.com.br/v1';

  constructor(private readonly config: ConfigService) {
    this.apiKey = this.config.get('ABACATEPAY_API_KEY') || '';
    this.webhookSecret = this.config.get('ABACATEPAY_WEBHOOK_SECRET') || '';
  }

  async createPixCharge(request: PixChargeRequest): Promise<Either<AppError, PixChargeResponse>> {
    if (!this.apiKey) {
      return left(new AppError('PAYMENT_CONFIG_ERROR', 'Payment provider not configured', 500));
    }

    try {
      const response = await fetch(`${this.baseUrl}/charge`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': this.apiKey,
        },
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`AbacatePay error: ${response.status} - ${errorText}`);
        return left(new AppError('PAYMENT_PROVIDER_ERROR', errorText, response.status));
      }

      return right((await response.json()) as PixChargeResponse);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`AbacatePay request failed: ${message}`);
      return left(new AppError('PAYMENT_REQUEST_FAILED', message, 500));
    }
  }

  verifyWebhook(signature: string, body: unknown): boolean {
    if (!this.webhookSecret) {
      return process.env.NODE_ENV !== 'production';
    }

    if (!signature) {
      return false;
    }

    const payload = typeof body === 'string' ? body : JSON.stringify(body);
    const expected = createHmac('sha256', this.webhookSecret).update(payload).digest('hex');

    return signature === expected;
  }
}
