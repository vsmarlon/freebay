import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsService } from './sms.service';

@Injectable()
export class TwilioSmsService extends SmsService {
  private readonly logger = new Logger(TwilioSmsService.name);

  constructor(private readonly config: ConfigService) {
    super();
  }

  async sendVerificationCode(phone: string, code: string): Promise<string | null> {
    const accountSid = this.config.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.config.get<string>('TWILIO_AUTH_TOKEN');
    const fromNumber = this.config.get<string>('TWILIO_FROM_NUMBER');

    if (!accountSid || !authToken || !fromNumber) {
      this.logger.warn('SMS not sent: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN or TWILIO_FROM_NUMBER is not configured');
      if (this.config.get<string>('NODE_ENV') !== 'production') {
        this.logger.debug(`[DEV ONLY] Verification code for +55${phone}: ${code}`);
      }
      return null;
    }

    const toNumber = `+55${phone}`;
    const body = new URLSearchParams({
      To: toNumber,
      From: fromNumber,
      Body: `Seu código de verificação FreeBay é ${code}. Ele expira em 10 minutos.`,
    });

    const credentials = Buffer.from(`${accountSid}:${authToken}`).toString('base64');

    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body.toString(),
      },
    );

    if (!response.ok) {
      const errorBody = await response.text();
      this.logger.error(`SMS send failed: Twilio API responded ${response.status} - ${errorBody}`);
      return null;
    }

    const payload = (await response.json()) as { sid?: string };
    return payload.sid ?? null;
  }
}
