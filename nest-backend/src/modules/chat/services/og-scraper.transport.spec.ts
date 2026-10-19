import { createServer, type RequestListener, type Server } from 'node:http';
import { OgScraperService, fetchPinnedHtml } from './og-scraper.service';
import { UrlSafetyService } from './url-safety.service';

describe('pinned Open Graph transport', () => {
  let server: Server | undefined;

  afterEach(async () => {
    if (server?.listening) await new Promise<void>((resolve, reject) => server?.close((error) => error ? reject(error) : resolve()));
    server = undefined;
  });

  async function serve(handler: RequestListener): Promise<number> {
    server = createServer(handler);
    await new Promise<void>((resolve, reject) => {
      server?.once('error', reject);
      server?.listen(0, '127.0.0.1', resolve);
    });
    const address = server.address();
    if (!address || typeof address === 'string') throw new Error('Test server failed to bind');
    return address.port;
  }

  it('connects to the selected pinned address and preserves the original HTTP Host', async () => {
    let peer: string | undefined;
    let host: string | undefined;
    const port = await serve((request, response) => {
      peer = request.socket.remoteAddress;
      host = request.headers.host;
      response.end('<html><title>Preview</title></html>');
    });

    const html = await fetchPinnedHtml(`http://origin.example:${port}/path`, '127.0.0.1', 1000);

    expect(html).toContain('<title>Preview</title>');
    expect(peer).toBe('127.0.0.1');
    expect(host).toBe(`origin.example:${port}`);
  });

  it('refuses redirects instead of contacting the redirect destination', async () => {
    let requestCount = 0;
    const port = await serve((_request, response) => {
      requestCount++;
      response.writeHead(302, { location: 'http://127.0.0.1:1/secret' }).end();
    });

    await expect(fetchPinnedHtml(`http://origin.example:${port}/`, '127.0.0.1', 1000)).rejects.toThrow('Redirects are not followed');
    expect(requestCount).toBe(1);
  });

  it('caps the response size and bounds a stalled response by the shared deadline', async () => {
    const tooLargePort = await serve((_request, response) => response.end(Buffer.alloc(256 * 1024 + 1)));
    await expect(fetchPinnedHtml(`http://origin.example:${tooLargePort}/`, '127.0.0.1', 1000)).rejects.toThrow('Response too large');
    await new Promise<void>((resolve, reject) => server?.close((error) => error ? reject(error) : resolve()));
    server = undefined;

    const stalledPort = await serve(() => undefined);
    await expect(fetchPinnedHtml(`http://origin.example:${stalledPort}/`, '127.0.0.1', 30)).rejects.toThrow('Request timeout');
  });

  it('parses a public preview from supplied HTML without asking the scraper to fetch its URL', async () => {
    let fetchCount = 0;
    const policy = new UrlSafetyService(async () => [{ address: '93.184.216.34', family: 4 }]);
    const service = new OgScraperService(policy, async () => {
      fetchCount++;
      return '<html><head><meta property="og:title" content="Known title"><meta property="og:description" content="Known description"><meta property="og:site_name" content="Known site"></head></html>';
    });

    const result = await service.scrape('https://example.test/article');

    expect(result).toEqual({
      title: 'Known title', description: 'Known description', imageUrl: null,
      siteName: 'Known site', url: 'https://example.test/article',
    });
    expect(fetchCount).toBe(1);
  });
});
