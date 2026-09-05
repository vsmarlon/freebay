import { existsSync, readFileSync, rmSync } from 'fs';
import { join } from 'path';
import { saveUpload } from './file.utils';

describe('saveUpload', () => {
  const written: string[] = [];

  afterAll(() => {
    for (const url of written) {
      const path = join(process.cwd(), url.replace('/uploads/', 'uploads/'));
      if (existsSync(path)) rmSync(path);
    }
  });

  function save(mimetype: string, body = 'x') {
    const url = saveUpload({ mimetype, buffer: Buffer.from(body) }, 'avatar');
    written.push(url);
    return url;
  }

  it('writes the buffer to disk and returns its public path', () => {
    const url = save('image/png', 'hello');

    expect(url).toMatch(/^\/uploads\/avatar\/[0-9a-f-]{36}\.png$/);
    const path = join(process.cwd(), url.replace('/uploads/', 'uploads/'));
    expect(readFileSync(path).toString()).toBe('hello');
  });

  it('never returns a base64 data uri', () => {
    expect(save('image/jpeg')).not.toContain('base64');
  });

  it('falls back to .bin for an unmapped mimetype', () => {
    expect(save('application/octet-stream')).toMatch(/\.bin$/);
  });

  it('gives every upload a distinct name', () => {
    expect(save('image/png')).not.toBe(save('image/png'));
  });
});
