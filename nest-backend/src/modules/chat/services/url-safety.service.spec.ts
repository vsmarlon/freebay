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
