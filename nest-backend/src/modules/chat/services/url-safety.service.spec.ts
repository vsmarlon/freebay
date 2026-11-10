import { UrlSafetyService } from './url-safety.service';

describe('UrlSafetyService', () => {
  let service: UrlSafetyService;

  beforeEach(() => {
    service = new UrlSafetyService();
  });

  it('marks legitimate https website as SAFE', () => {
    const result = service.verifyUrl('https://google.com/search?q=test');
    expect(result.isSafe).toBe(true);
    expect(result.riskLevel).toBe('SAFE');
    expect(result.host).toBe('google.com');
  });

  it('marks www prefix as normalized https and SAFE', () => {
    const result = service.verifyUrl('www.github.com/freebay');
    expect(result.normalizedUrl).toBe('https://www.github.com/freebay');
    expect(result.isSafe).toBe(true);
  });

  it('marks javascript: URI scheme as DANGEROUS and blocked', () => {
    const result = service.verifyUrl('javascript:alert(1)');
    expect(result.isSafe).toBe(false);
    expect(result.riskLevel).toBe('DANGEROUS');
    expect(result.riskReasons.length).toBeGreaterThan(0);
  });

  it('marks private localhost IP as DANGEROUS', () => {
    const result = service.verifyUrl('http://127.0.0.1:8080/admin');
    expect(result.isSafe).toBe(false);
    expect(result.riskLevel).toBe('DANGEROUS');
    expect(result.riskReasons).toContain('Endereço de rede local ou IP privado não permitido.');
  });

  it('rejects mapped IPv6 and any non-public address in a mixed DNS result', async () => {
    expect(service.isPublicAddress('::ffff:7f00:1')).toBe(false);
    expect(service.isPublicAddress('2606:4700:4700::1111')).toBe(true);
    expect(service.isPublicAddress('198.51.100.25')).toBe(false);
    expect(service.isPublicAddress('2002:c000:0201::1')).toBe(false);
    expect(service.isPublicAddress('2001:0:4136:e378:8000:63bf:3fff:fdd2')).toBe(false);
    expect(service.isPublicAddress('2001:1::1')).toBe(true);
    expect(service.isPublicAddress('64:ff9b::5db8:d822')).toBe(true);
    expect(service.isPublicAddress('64:ff9b::a00:1')).toBe(false);
    expect(service.isPublicAddress('192.0.0.9')).toBe(true);
    expect(service.isPublicAddress('192.0.1.10')).toBe(true);

    const mixedResolver = new UrlSafetyService(async () => [
      { address: '93.184.216.34', family: 4 },
      { address: '10.20.30.40', family: 4 },
    ]);
    await expect(mixedResolver.resolvePublicAddresses('https://example.test/')).rejects.toThrow('Non-public destination');
  });

  it.each([
    'https://user:password@example.com/',
    'https://example.com:8080/',
    'https://example.com:80/',
  ])('rejects credentials or nonstandard ports before resolving: %s', async (url) => {
    const resolver = jest.fn(async () => [{ address: '93.184.216.34', family: 4 }]);
    const policy = new UrlSafetyService(resolver);

    await expect(policy.resolvePublicAddresses(url)).rejects.toThrow('Unsafe URL');
    expect(resolver).not.toHaveBeenCalled();
  });

  it('marks dangerous executable extensions as DANGEROUS', () => {
    const result = service.verifyUrl('https://suspicious-files.net/malware.exe');
    expect(result.isSafe).toBe(false);
    expect(result.riskLevel).toBe('DANGEROUS');
  });

  it('marks phishing keyword domains as DANGEROUS', () => {
    const result = service.verifyUrl('https://freebay-login-secure.xyz');
    expect(result.isSafe).toBe(false);
    expect(result.riskLevel).toBe('DANGEROUS');
  });
});
