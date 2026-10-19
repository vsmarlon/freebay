import { Inject, Injectable, Optional } from '@nestjs/common';
import { request as httpRequest } from 'node:http';
import { request as httpsRequest } from 'node:https';
import type { RequestOptions } from 'node:http';
import { isIP } from 'node:net';
import ogs from 'open-graph-scraper';
import { UrlSafetyService } from './url-safety.service';

export interface OgMetadata {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  siteName: string | null;
  url: string;
}

const URL_REGEX = /https?:\/\/[^\s]+/;
const SCRAPE_TIMEOUT_MS = 3000;
const MAX_RESPONSE_BYTES = 256 * 1024;
export const OG_HTML_FETCHER = Symbol('OG_HTML_FETCHER');
export type OgHtmlFetcher = (url: string, verifiedAddress: string, timeoutMs: number) => Promise<string>;

/** Transport helper; `address` must come from UrlSafetyService.resolvePublicAddresses. */
export function fetchPinnedHtml(url: string, address: string, timeoutMs: number): Promise<string> {
  const parsed = new URL(url);
  const family = address.includes(':') ? 6 : 4;
  const request = parsed.protocol === 'https:' ? httpsRequest : httpRequest;
  return new Promise<string>((resolve, reject) => {
    const options: RequestOptions = {
      protocol: parsed.protocol,
      hostname: parsed.hostname.replace(/^\[|\]$/g, ''),
      port: parsed.port || undefined,
      path: `${parsed.pathname}${parsed.search}`,
      method: 'GET',
      headers: { Host: parsed.host, 'User-Agent': 'FreeBay-LinkPreview/1.0', Accept: 'text/html' },
      lookup: (_hostname, lookupOptions, callback) => {
        if (typeof lookupOptions === 'object' && lookupOptions.all) callback(null, [{ address, family }]);
        else callback(null, address, family);
      },
      ...(parsed.protocol === 'https:' && !isIP(parsed.hostname.replace(/^\[|\]$/g, ''))
        ? { servername: parsed.hostname.replace(/^\[|\]$/g, '') }
        : {}),
    };
    const req = request(options, (res) => {
      if ((res.statusCode ?? 0) >= 300 && (res.statusCode ?? 0) < 400) {
        res.destroy();
        reject(new Error('Redirects are not followed'));
        return;
      }
      if ((res.statusCode ?? 0) < 200 || (res.statusCode ?? 0) >= 300) {
        res.destroy();
        reject(new Error('Non-success response'));
        return;
      }
      const chunks: Buffer[] = [];
      let bytes = 0;
      res.on('data', (chunk: Buffer | string) => {
        const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
        bytes += buffer.length;
        if (bytes > MAX_RESPONSE_BYTES) {
          req.destroy(new Error('Response too large'));
          return;
        }
        chunks.push(buffer);
      });
      res.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
      res.on('error', reject);
    });
    const timer = setTimeout(() => req.destroy(new Error('Request timeout')), timeoutMs);
    req.on('close', () => clearTimeout(timer));
    req.setTimeout(timeoutMs, () => req.destroy(new Error('Request timeout')));
    req.on('error', reject);
    req.end();
  });
}

@Injectable()
export class OgScraperService {
  constructor(
    private readonly urlSafety: UrlSafetyService,
    @Optional() @Inject(OG_HTML_FETCHER) private readonly fetchHtml: OgHtmlFetcher = fetchPinnedHtml,
  ) {}
  extractFirstUrl(text: string): string | null {
    const match = text.match(URL_REGEX);
    return match ? match[0] : null;
  }

  async scrape(url: string): Promise<OgMetadata | null> {
    const deadline = Date.now() + SCRAPE_TIMEOUT_MS;
    const remainingMs = () => Math.max(1, deadline - Date.now());
    try {
      const addresses = await new Promise<string[]>((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('DNS timeout')), remainingMs());
        this.urlSafety.resolvePublicAddresses(url).then(resolve, reject).finally(() => clearTimeout(timer));
      });
      const html = await this.fetchHtml(url, addresses[0], remainingMs());
      const result = await ogs({ html });
      if (!result || result.error) return null;
      const data = result.result;
      return {
        title: data.ogTitle ?? null,
        description: data.ogDescription ?? null,
        imageUrl: data.ogImage?.[0]?.url ?? null,
        siteName: data.ogSiteName ?? null,
        url,
      };
    } catch {
      return null;
    }
  }
}
