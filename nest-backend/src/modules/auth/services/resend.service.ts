import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ResendService {
  private readonly logger = new Logger(ResendService.name);

  constructor(private config: ConfigService) {}

  async sendRecoveryCode(email: string, code: string): Promise<string | null> {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    const fromEmail = this.config.get<string>('RESEND_FROM_EMAIL');

    if (!apiKey || !fromEmail) {
      this.logger.warn('Recovery email not sent: RESEND_API_KEY or RESEND_FROM_EMAIL is not configured');
      return null;
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromEmail,
        to: email,
        subject: 'Seu código de recuperação FreeBay',
        html: `<p>Seu código de recuperação é <strong>${code}</strong>.</p><p>Ele expira em 10 minutos.</p>`,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Recovery email failed: Resend API responded ${response.status} - ${body}`);
      return null;
    }

    const payload = await response.json() as { id?: string };
    return payload.id ?? null;
  }
}
