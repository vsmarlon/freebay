import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { lookup } from 'node:dns/promises';
import { isIP } from 'node:net';

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
export const URL_DNS_RESOLVER = Symbol('URL_DNS_RESOLVER');
export type UrlDnsResolver = (hostname: string) => Promise<Array<{ address: string; family: number }>>;

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

  constructor(@Optional() @Inject(URL_DNS_RESOLVER) private readonly dnsResolver?: UrlDnsResolver) {}

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
    const host = parsedUrl.hostname.toLowerCase().replace(/^\[|\]$/g, '');
    const pathname = parsedUrl.pathname.toLowerCase();

    const invalidPort = parsedUrl.port &&
      ((scheme === 'http:' && parsedUrl.port !== '80') || (scheme === 'https:' && parsedUrl.port !== '443'));
    if (parsedUrl.username || parsedUrl.password || invalidPort) {
      reasons.push('Credenciais ou porta não permitida.');
      isBlocked = true;
      riskLevel = 'DANGEROUS';
    }

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

  async verifyPublicDestination(rawUrl: string): Promise<UrlSafetyVerification> {
    const result = this.verifyUrl(rawUrl);
    if (!result.isSafe) return result;
    try {
      await this.resolvePublicAddresses(result.normalizedUrl);
      return result;
    } catch {
      return this.markUnsafe(result);
    }
  }

  async resolvePublicAddresses(rawUrl: string): Promise<string[]> {
    const verified = this.verifyUrl(rawUrl);
    if (!verified.isSafe) throw new Error('Unsafe URL');
    const hostname = new URL(verified.normalizedUrl).hostname.replace(/^\[|\]$/g, '');
    const addresses = isIP(hostname)
      ? [{ address: hostname }]
      : await (this.dnsResolver
        ? this.dnsResolver(hostname)
        : lookup(hostname, { all: true, verbatim: true }));
    if (!addresses.length || addresses.some(({ address }) => !this.isPublicAddress(address))) {
      throw new Error('Non-public destination');
    }
    return addresses.map(({ address }) => address);
  }

  isPublicAddress(address: string): boolean {
    const family = isIP(address);
    if (family === 4) {
      const value = address.split('.').reduce((result, octet) => (result << 8n) | BigInt(octet), 0n);
      const protocolAssignments = this.inCidr(value, '192.0.0.0', 24, 32);
      if (protocolAssignments && address !== '192.0.0.9' && address !== '192.0.0.10') return false;
      const nonPublicRanges = [
        ['0.0.0.0', 8], ['10.0.0.0', 8], ['100.64.0.0', 10], ['127.0.0.0', 8],
        ['169.254.0.0', 16], ['172.16.0.0', 12], ['192.0.2.0', 24],
        ['192.88.99.0', 24], ['192.168.0.0', 16], ['198.18.0.0', 15], ['198.51.100.0', 24],
        ['203.0.113.0', 24], ['224.0.0.0', 4], ['240.0.0.0', 4],
      ] as const;
      return !nonPublicRanges.some(([network, prefix]) => this.inCidr(value, network, prefix, 32));
    }
    if (family !== 6) return false;
    const value = this.ipv6Value(address);
    const mappedPrefix = BigInt('0x00000000000000000000ffff00000000');
    if ((value >> 32n) === (mappedPrefix >> 32n)) return false;
    if (this.inCidr(value, '64:ff9b::', 96, 128)) {
      const embeddedIpv4 = Number(value & 0xffffffffn);
      const embedded = [24, 16, 8, 0].map((shift) => (embeddedIpv4 >>> shift) & 255).join('.');
      return this.isPublicAddress(embedded);
    }
    if (!this.inCidr(value, '2000::', 3, 128)) return false;
    // IANA IPv6 special registry (2025-10-09): 2001::/23 is non-global unless
    // a more-specific globally-reachable assignment overrides the parent.
    const globallyReachableAssignments = [
      ['2001:1::1', 128], ['2001:1::2', 128], ['2001:1::3', 128],
      ['2001:3::', 32], ['2001:4:112::', 48], ['2001:20::', 28], ['2001:30::', 28],
    ] as const;
    if (this.inCidr(value, '2001::', 23, 128)) {
      return globallyReachableAssignments.some(([network, prefix]) => this.inCidr(value, network, prefix, 128));
    }
    const nonPublicRanges = [
      ['2001:db8::', 32], // documentation
      ['2002::', 16], // 6to4 transition
      ['3fff::', 20], // documentation
    ] as const;
    return !nonPublicRanges.some(([network, prefix]) => this.inCidr(value, network, prefix, 128));
  }

  private inCidr(value: bigint, network: string, prefix: number, familyBits: 32 | 128): boolean {
    const base = familyBits === 32
      ? network.split('.').reduce((result, octet) => (result << 8n) | BigInt(octet), 0n)
      : this.ipv6Value(network);
    const shift = BigInt(familyBits - prefix);
    return (value >> shift) === (base >> shift);
  }

  private ipv6Value(address: string): bigint {
    let normalized = address.toLowerCase().split('%')[0];
    if (normalized.includes('.')) {
      const split = normalized.lastIndexOf(':');
      const octets = normalized.slice(split + 1).split('.').map(Number);
      normalized = `${normalized.slice(0, split)}:${((octets[0] << 8) | octets[1]).toString(16)}:${((octets[2] << 8) | octets[3]).toString(16)}`;
    }
    const halves = normalized.split('::');
    const left = halves[0] ? halves[0].split(':') : [];
    const right = halves[1] ? halves[1].split(':') : [];
    const groups = [...left, ...Array(8 - left.length - right.length).fill('0'), ...right];
    return groups.reduce((value, group) => (value << 16n) | BigInt(`0x${group || '0'}`), 0n);
  }

  private markUnsafe(result: UrlSafetyVerification): UrlSafetyVerification {
    return { ...result, isSafe: false, riskLevel: 'DANGEROUS', riskReasons: [...result.riskReasons, 'Resolved destination is not public.'] };
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
