import { Injectable, Logger } from '@nestjs/common';

export type UrlRiskLevel = 'SAFE' | 'SUSPICIOUS' | 'DANGEROUS';

export interface UrlSafetyVerification {
  url: string;
  normalizedUrl: string;
  host: string;
  isSafe: boolean;
  riskLevel: UrlRiskLevel;
  riskReasons: string[];
  destinationDomain: string;
}

const ALLOWED_SCHEMES = new Set(['http:', 'https:']);

const DANGEROUS_SCHEMES = new Set([
  'javascript:',
  'data:',
  'file:',
  'intent:',
  'blob:',
  'android-app:',
  'content:',
  'about:',
  'vbscript:',
]);

const DANGEROUS_EXTENSIONS = [
  '.exe',
  '.apk',
  '.dmg',
  '.pkg',
  '.bat',
  '.cmd',
  '.scr',
  '.vbs',
  '.js',
  '.msi',
  '.sh',
  '.bin',
  '.jar',
  '.reg',
  '.iso',
];

const PHISHING_KEYWORDS = [
  'freebay-login',
  'freebay-auth',
  'freebay-pagamento',
  'freebay-suporte',
  'mercadopago-liberar',
  'seguranca-pix',
  'confirmacao-escrow',
  'recuperar-conta',
];

const TRUSTED_DOMAINS = new Set([
  'freebay.app',
  'freebay.com',
  'github.com',
  'google.com',
  'youtube.com',
  'instagram.com',
  'twitter.com',
  'x.com',
  'linkedin.com',
  'wikipedia.org',
  'apple.com',
  'play.google.com',
]);

@Injectable()
export class UrlSafetyService {
  private readonly logger = new Logger(UrlSafetyService.name);

  normalizeUrl(rawUrl: string): string {
    let trimmed = rawUrl.trim();
    if (trimmed.startsWith('www.')) {
      trimmed = `https://${trimmed}`;
    }
    return trimmed;
  }

  verifyUrl(rawUrl: string): UrlSafetyVerification {
    const normalized = this.normalizeUrl(rawUrl);
    const reasons: string[] = [];
    let isBlocked = false;
    let riskLevel: UrlRiskLevel = 'SAFE';

    let parsedUrl: URL;
    try {
      parsedUrl = new URL(normalized);
    } catch {
      return {
        url: rawUrl,
        normalizedUrl: normalized,
        host: 'invalid-url',
        isSafe: false,
        riskLevel: 'DANGEROUS',
        riskReasons: ['URL inválida ou malformada.'],
        destinationDomain: 'invalid-url',
      };
    }

    const scheme = parsedUrl.protocol.toLowerCase();
    const host = parsedUrl.hostname.toLowerCase();
    const pathname = parsedUrl.pathname.toLowerCase();

    // 1. Protocol validation
    if (DANGEROUS_SCHEMES.has(scheme)) {
      reasons.push(`Protocolo potencialmente perigoso detectado (${scheme}).`);
      isBlocked = true;
      riskLevel = 'DANGEROUS';
    } else if (!ALLOWED_SCHEMES.has(scheme)) {
      reasons.push(`Protocolo não suportado (${scheme}).`);
      isBlocked = true;
      riskLevel = 'DANGEROUS';
    }

    // 2. Private IP / SSRF
    if (this.isPrivateOrLocalHost(host)) {
      reasons.push('Endereço de rede local ou IP privado não permitido.');
      isBlocked = true;
      riskLevel = 'DANGEROUS';
    }

    // 3. Executable / Dangerous payload extensions
    for (const ext of DANGEROUS_EXTENSIONS) {
      if (pathname.endsWith(ext)) {
        reasons.push(`Arquivo executável perigoso detectado (${ext}).`);
        isBlocked = true;
        riskLevel = 'DANGEROUS';
        break;
      }
    }

    // 4. Phishing / Brand Impersonation in domain
    for (const kw of PHISHING_KEYWORDS) {
      if (host.includes(kw)) {
        reasons.push('Possível tentativa de phishing ou falsificação de marca.');
        riskLevel = 'DANGEROUS';
        break;
      }
    }

    // 5. Punycode / Homograph attack detection
    if (host.startsWith('xn--') || host.includes('.xn--')) {
      reasons.push('Domínio com caracteres internacionais codificados (punycode).');
      if (riskLevel !== 'DANGEROUS') {
        riskLevel = 'SUSPICIOUS';
      }
    }

    // 6. Plain HTTP
    if (scheme === 'http:' && !this.isLocalHost(host)) {
      reasons.push('Conexão HTTP não criptografada.');
      if (riskLevel === 'SAFE') {
        riskLevel = 'SUSPICIOUS';
      }
    }

    // 7. Unusual Port Check
    if (parsedUrl.port && parsedUrl.port !== '80' && parsedUrl.port !== '443' && parsedUrl.port !== '8080') {
      reasons.push(`Porta de conexão incomum (${parsedUrl.port}).`);
      if (riskLevel === 'SAFE') {
        riskLevel = 'SUSPICIOUS';
      }
    }

    // 8. Whitelist override for safe domains
    if (this.isTrusted(host) && riskLevel === 'SAFE') {
      // verified safe
    }

    return {
      url: rawUrl,
      normalizedUrl: normalized,
      host,
      isSafe: !isBlocked && riskLevel !== 'DANGEROUS',
      riskLevel,
      riskReasons: reasons,
      destinationDomain: host,
    };
  }

  private isTrusted(host: string): boolean {
    if (TRUSTED_DOMAINS.has(host)) return true;
    for (const domain of TRUSTED_DOMAINS) {
      if (host.endsWith(`.${domain}`)) return true;
    }
    return false;
  }

  private isLocalHost(host: string): boolean {
    return host === 'localhost' || host === '127.0.0.1' || host === '::1';
  }

  private isPrivateOrLocalHost(host: string): boolean {
    if (this.isLocalHost(host)) return true;
    if (host === '0.0.0.0' || host === '169.254.169.254') return true;

    const ipParts = host.split('.').map((p) => parseInt(p, 10));
    if (ipParts.length === 4 && ipParts.every((p) => !isNaN(p) && p >= 0 && p <= 255)) {
      const [p1, p2] = ipParts;
      if (p1 === 10) return true;
      if (p1 === 172 && p2 >= 16 && p2 <= 31) return true;
      if (p1 === 192 && p2 === 168) return true;
      if (p1 === 127) return true;
      if (p1 === 169 && p2 === 254) return true;
    }

    return false;
  }
}
