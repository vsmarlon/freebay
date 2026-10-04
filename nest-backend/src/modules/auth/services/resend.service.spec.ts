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

  it('uses a trusted same-origin legal URL and keeps deletion tokens out of URL queries', async () => {
    const fetchMock = jest.fn<ReturnType<typeof fetch>, Parameters<typeof fetch>>().mockResolvedValue(
      new Response(JSON.stringify({ id: 'message-id' }), { status: 200 }),
    );
    global.fetch = fetchMock;
    const config = new ConfigService({ RESEND_API_KEY: 'test-key', NODE_ENV: 'test' });

    await new ResendService(config).sendMagicLink(
      'user@example.com', 'delete.raw-token', 'en', 'credential-id', 'account-deletion', 'http://localhost:3000',
    );

    const body = String(fetchMock.mock.calls[0]?.[1]?.body);
    expect(body).toContain('http://localhost:3000/legal/delete-account.html#token=delete.raw-token');
    expect(body).not.toContain('?token=delete.raw-token');
    expect(body).toContain('explicit confirmation');
  });

  it('does not send an account-deletion email link from an invalid production origin', async () => {
    const fetchMock = jest.fn<ReturnType<typeof fetch>, Parameters<typeof fetch>>();
    global.fetch = fetchMock;
    const config = new ConfigService({ RESEND_API_KEY: 'test-key', NODE_ENV: 'production' });

    const result = await new ResendService(config).sendMagicLink(
      'user@example.com', 'delete.raw-token', 'en', 'credential-id', 'account-deletion', 'http://evil.example.com',
    );

    expect(result).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

});
