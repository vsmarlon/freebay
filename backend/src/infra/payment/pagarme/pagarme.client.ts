// TODO: Implement Pagar.me API client
// Docs: https://docs.pagar.me/reference

import { env } from '@/env';

export class PagarmeClient {
  private apiKey: string;
  private baseUrl = 'https://api.pagar.me/core/v5';

  constructor() {
    this.apiKey = env.PAGARME_API_KEY;
  }

  private getHeaders() {
    return {
      Authorization: `Basic ${Buffer.from(this.apiKey + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    };
  }

  async createPixOrder(): Promise<{ orderId: string; pixQrCode: string; pixQrCodeUrl: string }> {
    throw new Error('Not implemented — see Pagar.me API docs');
  }

  async createRecipient(): Promise<{ recipientId: string }> {
    throw new Error('Not implemented — see Pagar.me API docs');
  }

  async createTransfer(): Promise<{ transferId: string }> {
    throw new Error('Not implemented — see Pagar.me API docs');
  }

  verifyWebhookSignature(): boolean {
    // TODO: Validate webhook signature
    return false;
  }
}
