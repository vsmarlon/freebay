import { ConfigService } from '@nestjs/config';
import { ResendService } from './resend.service';

describe('ResendService magic links', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('sends with the credential-stable idempotency key', async () => {
    const fetchMock = jest.fn<ReturnType<typeof fetch>, Parameters<typeof fetch>>().mockResolvedValue(
      new Response(JSON.stringify({ id: 'message-id' }), { status: 200 }),
    );
    global.fetch = fetchMock;
    const config = new ConfigService({
        RESEND_API_KEY: 'test-key',
        RESEND_FROM_EMAIL: 'FreeBay <test@example.com>',
        WEB_APP_URL: 'https://example.com',
    });

    const result = await new ResendService(config).sendMagicLink(
      'user@example.com',
      'raw-token',
      'en',
      'credential-id',
    );

    expect(result).toEqual({ id: 'message-id' });
    expect(fetchMock).toHaveBeenCalledWith(
      'https://api.resend.com/emails',
      expect.objectContaining({
        idempotencyKey: 'magic-link/credential-id',
      }),
    );
  });
});
