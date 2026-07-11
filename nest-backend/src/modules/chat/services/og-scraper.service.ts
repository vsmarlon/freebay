import { Injectable } from '@nestjs/common';
import ogs from 'open-graph-scraper';
import type { SuccessResult } from 'open-graph-scraper/types/lib/types';

export interface OgMetadata {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  siteName: string | null;
  url: string;
}

const URL_REGEX = /https?:\/\/[^\s]+/;
const SCRAPE_TIMEOUT_MS = 3000;

@Injectable()
export class OgScraperService {
  extractFirstUrl(text: string): string | null {
    const match = text.match(URL_REGEX);
    return match ? match[0] : null;
  }

  async scrape(url: string): Promise<OgMetadata | null> {
    try {
      const result = await Promise.race([
        ogs({ url, timeout: SCRAPE_TIMEOUT_MS }),
        new Promise<null>((resolve) => setTimeout(() => resolve(null), SCRAPE_TIMEOUT_MS + 500)),
      ]);
      if (!result || result.error) return null;
      const { result: data } = result as SuccessResult;
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
