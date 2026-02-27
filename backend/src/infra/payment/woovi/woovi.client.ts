// TODO: Implement Woovi (OpenPix) API client for Pix payments
// Docs: https://developers.openpix.com.br/

import { env } from '@/env';

export class WooviClient {
  private appId: string;
  private baseUrl = 'https://api.openpix.com.br/api/v1';

  constructor() {
    this.appId = env.WOOVI_APP_ID;
  }

  private getHeaders() {
    return {
      Authorization: this.appId,
      'Content-Type': 'application/json',
    };
  }

  async createCharge(): Promise<{ chargeId: string; pixQrCode: string; pixQrCodeUrl: string }> {
    throw new Error('Not implemented — see Woovi API docs');
  }

  verifyWebhookSignature(): boolean {
    // TODO: Validate webhook signature
    return false;
  }
}
