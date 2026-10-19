import { redact } from './redact.util';

describe('redact', () => {
  it('redacts case-insensitive credentials and personal identifiers in nested payloads', () => {
    expect(redact({ AUTHORIZATION: 'bearer secret', nested: { Email: 'a@b.c', phoneNumber: '123', CPF: '123', sessionToken: 't', firstName: 'Ada' } })).toEqual({
      AUTHORIZATION: '[REDACTED]',
      nested: { Email: '[REDACTED]', phoneNumber: '[REDACTED]', CPF: '[REDACTED]', sessionToken: '[REDACTED]', firstName: '[REDACTED]' },
    });
  });

  it('redacts view-once opening keys from request bodies and headers', () => {
    expect(redact({ openingKey: '550e8400-e29b-41d4-a716-446655440000', headers: { 'x-view-once-opening': '550e8400-e29b-41d4-a716-446655440000' } })).toEqual({
      openingKey: '[REDACTED]',
      headers: { 'x-view-once-opening': '[REDACTED]' },
    });
  });
});
