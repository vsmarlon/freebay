import { OgScraperService } from './og-scraper.service';

describe('OgScraperService', () => {
  let sut: OgScraperService;

  beforeEach(() => {
    sut = new OgScraperService();
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
});
