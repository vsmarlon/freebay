import { describe, expect, it } from 'vitest';
import { redactSensitiveDiagnostics } from './bug-report-sanitizer';

describe('bug report diagnostic redaction', () => {
  it('redacts credential assignments, bearer/JWT tokens and card numbers while retaining useful logs', () => {
    const sanitized = redactSensitiveDiagnostics(
      'submit failed; password=hunter2 Authorization: Bearer abc.def.ghi 4111 1111 1111 1111 {"refreshToken":"secret value"}',
    );
    expect(sanitized).toContain('submit failed');
    expect(sanitized).not.toContain('hunter2');
    expect(sanitized).not.toContain('abc.def.ghi');
    expect(sanitized).not.toContain('4111');
    expect(sanitized).not.toContain('secret value');
  });
});
