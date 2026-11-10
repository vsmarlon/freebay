import ogs from 'open-graph-scraper';
import { OgScraperService } from './og-scraper.service';
import { UrlSafetyService } from './url-safety.service';

jest.mock('open-graph-scraper', () => ({
  __esModule: true,
  default: jest.fn().mockResolvedValue({ error: false, result: {}, response: {}, html: '' }),
}));

it('does not hand a private destination to the external scraper', async () => {
  const service = new OgScraperService(new UrlSafetyService());

  await expect(service.scrape('http://127.0.0.1/')).resolves.toBeNull();

  expect(ogs).not.toHaveBeenCalled();
});

it('rejects mixed public/private DNS answers before opening a socket', async () => {
  const resolver = jest.fn(async () => [
    { address: '93.184.216.34', family: 4 },
    { address: '10.0.0.8', family: 4 },
  ]);
  const fetchHtml = jest.fn(async () => '<html></html>');
  const service = new OgScraperService(new UrlSafetyService(resolver), fetchHtml);

  await expect(service.scrape('https://mixed.example/')).resolves.toBeNull();

  expect(resolver).toHaveBeenCalledTimes(1);
  expect(fetchHtml).not.toHaveBeenCalled();
  expect(ogs).not.toHaveBeenCalled();
});
