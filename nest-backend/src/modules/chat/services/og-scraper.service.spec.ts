import { OgScraperService } from './og-scraper.service';
import { UrlSafetyService } from './url-safety.service';

describe('OgScraperService', () => {
  let sut: OgScraperService;

  beforeEach(() => {
    sut = new OgScraperService(new UrlSafetyService());
  });

  describe('extractFirstUrl', () => {
    it('returns first URL found in a string', () => {
      expect(sut.extractFirstUrl('check https://example.com out')).toBe('https://example.com');
    });

    it('returns null when no URL present', () => {
      expect(sut.extractFirstUrl('no url here')).toBeNull();
    });

    it('returns null for empty string', () => {
      expect(sut.extractFirstUrl('')).toBeNull();
    });
  });

  it('does not fetch private or mapped-private destinations', async () => {
    await expect(sut.scrape('http://127.0.0.1/')).resolves.toBeNull();
    await expect(sut.scrape('http://[::ffff:127.0.0.1]/')).resolves.toBeNull();
  });
});
