import 'reflect-metadata';
import { Controller, Module, Post, Req, UploadedFile, UploadedFiles, UseInterceptors } from '@nestjs/common';
import { NestApplication, NestFactory } from '@nestjs/core';
import { Request } from 'express';
import { IncomingMessage, request as httpRequest, Server } from 'node:http';
import { BoundedMultipartInterceptor } from './bounded-multipart.interceptor';

let server: Server;
let app: NestApplication;
let handlerCalls = 0;
const probes = new Map<string, {
  firstData: Promise<void>;
  closed: Promise<void>;
  sawAborted: boolean;
  errors: string[];
  resolveFirstData: () => void;
  resolveClosed: () => void;
}>();

@Controller()
class UploadProbeController {
  @Post()
  @UseInterceptors(BoundedMultipartInterceptor('media', 4))
  upload(@Req() request: Request, @UploadedFiles() files: Express.Multer.File[] = [], @UploadedFile() file?: Express.Multer.File) {
    handlerCalls += 1;
    return { field: request.body.field, count: files.length + (file ? 1 : 0), fileName: file?.originalname };
  }

  @Post('/small')
  @UseInterceptors(BoundedMultipartInterceptor('media', 1, 64 * 1024))
  small(@Req() request: Request, @UploadedFile() file?: Express.Multer.File) {
    handlerCalls += 1;
    return { field: request.body.field, bytes: file?.buffer.toString('hex') };
  }
}

@Module({ controllers: [UploadProbeController] })
class TestModule {}

function recordTransport(request: IncomingMessage): void {
  const id = request.headers['x-transport-probe'];
  if (typeof id !== 'string') return;
  const probe = probes.get(id);
  if (!probe) return;
  request.once('data', probe.resolveFirstData);
  request.on('aborted', () => { probe.sawAborted = true; });
  request.on('error', (error) => {
    const code = 'code' in error && typeof error.code === 'string' ? error.code : 'unknown';
    probe.errors.push(code);
  });
  request.once('close', probe.resolveClosed);
}

function createProbe(id: string) {
  let resolveFirstData = () => {};
  let resolveClosed = () => {};
  const probe = {
    firstData: new Promise<void>((resolve) => { resolveFirstData = resolve; }),
    closed: new Promise<void>((resolve) => { resolveClosed = resolve; }),
    sawAborted: false,
    errors: [] as string[],
    resolveFirstData: () => resolveFirstData(),
    resolveClosed: () => resolveClosed(),
  };
  probes.set(id, probe);
  return probe;
}

async function withinThreeSeconds<T>(promise: Promise<T>, label = 'HTTP transport probe'): Promise<T> {
  let timer: NodeJS.Timeout | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<T>((_, reject) => { timer = setTimeout(() => reject(new Error(`${label} timed out`)), 3000); }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

function openProbedRequest(id: string, headers: Record<string, string>) {
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('HTTP test server has no TCP address');
  return httpRequest({ host: '127.0.0.1', port: address.port, method: 'POST', path: '/', headers: {
    'content-type': 'multipart/form-data; boundary=bound', 'x-transport-probe': id, ...headers,
  } });
}

function listenForClientError(request: ReturnType<typeof httpRequest>): Promise<string> {
  return new Promise((resolve) => request.once('error', (error) => {
    resolve('code' in error && typeof error.code === 'string' ? error.code : 'unknown');
  }));
}

function send(body: Buffer, headers: Record<string, string> = {}): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const address = server.address();
    if (!address || typeof address === 'string') return reject(new Error('HTTP test server has no TCP address'));
    const request = httpRequest({
      host: '127.0.0.1', port: address.port, method: 'POST', path: '/',
      headers: { 'content-type': 'multipart/form-data; boundary=bound', ...headers },
    }, (response) => {
      const chunks: Buffer[] = [];
      response.on('data', (chunk: Buffer) => chunks.push(chunk));
      response.on('end', () => resolve({ status: response.statusCode ?? 0, body: Buffer.concat(chunks).toString() }));
    });
    request.on('error', reject);
    request.end(body);
  });
}

function multipart(parts: Buffer[]): Buffer {
  return Buffer.concat([
    Buffer.from('--bound\r\nContent-Disposition: form-data; name="field"\r\n\r\nvalue\r\n'),
    ...parts.flatMap((part, index) => [
      Buffer.from(`--bound\r\nContent-Disposition: form-data; name="media"; filename="${index}.bin"\r\nContent-Type: application/octet-stream\r\n\r\n`),
      part, Buffer.from('\r\n'),
    ]),
    Buffer.from('--bound--\r\n'),
  ]);
}

function sendFragmented(body: Buffer): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const address = server.address();
    if (!address || typeof address === 'string') return reject(new Error('HTTP test server has no TCP address'));
    const request = httpRequest({ host: '127.0.0.1', port: address.port, method: 'POST', path: '/small',
      headers: { 'content-type': 'multipart/form-data; boundary=bound', 'transfer-encoding': 'chunked' } }, (response) => {
      const chunks: Buffer[] = [];
      response.on('data', (chunk: Buffer) => chunks.push(chunk));
      response.on('end', () => resolve({ status: response.statusCode ?? 0, body: Buffer.concat(chunks).toString() }));
    });
    request.on('error', reject);
    let offset = 0;
    const writeNext = () => {
      while (offset < body.length) {
        const accepted = request.write(body.subarray(offset, offset + 1));
        offset += 1;
        if (!accepted) { request.once('drain', writeNext); return; }
      }
      request.end();
    };
    writeNext();
  });
}

describe('BoundedMultipartInterceptor HTTP', () => {
  beforeAll(async () => {
    app = await NestFactory.create(TestModule, { logger: false });
    await app.init();
    server = app.getHttpAdapter().getInstance().listen(0, '127.0.0.1');
    await new Promise<void>((resolve) => server.once('listening', resolve));
    server.prependListener('request', recordTransport);
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    await app.close();
  });

  it('replays multipart fields/files, rejects chunked and declared raw oversize, and leaves JSON alone', async () => {
    const before = handlerCalls;
    expect(await send(multipart([Buffer.from('small')]))).toMatchObject({ status: 201, body: expect.stringContaining('"count":1') });
    expect(await send(multipart([Buffer.from('1'), Buffer.from('2'), Buffer.from('3'), Buffer.from('4')]))).toMatchObject({ status: 201, body: expect.stringContaining('"count":4') });
    expect(await send(multipart([Buffer.from('1'), Buffer.from('2'), Buffer.from('3'), Buffer.from('4'), Buffer.from('5')]))).toMatchObject({ status: 400 });
    expect(handlerCalls).toBe(before + 2);
    const oversized = multipart([Buffer.alloc(11 * 1024 * 1024), Buffer.alloc(11 * 1024 * 1024)]);
    expect(await send(oversized, { 'transfer-encoding': 'chunked' })).toMatchObject({ status: 413 });
    expect(await send(oversized, { 'content-length': String(oversized.length) })).toMatchObject({ status: 413 });
    const fields = Array.from({ length: 65 }, (_, index) => Buffer.from(`--bound\r\nContent-Disposition: form-data; name="field${index}"\r\n\r\nx\r\n`));
    expect(await send(Buffer.concat([...fields, Buffer.from('--bound--\r\n')]))).toMatchObject({ status: 400 });
    const hugeField = Buffer.from(`--bound\r\nContent-Disposition: form-data; name="field"\r\n\r\n${'x'.repeat(4097)}\r\n--bound--\r\n`);
    expect(await send(hugeField)).toMatchObject({ status: 400 });
    const tooManyParts = Array.from({ length: 69 }, (_, index) => Buffer.from(`--bound\r\nContent-Disposition: form-data; name="field${index}"\r\n\r\nx\r\n`));
    expect(await send(Buffer.concat([...tooManyParts, Buffer.from('--bound--\r\n')]))).toMatchObject({ status: 400 });
    expect(handlerCalls).toBe(before + 2);
    expect(await send(Buffer.from('{"field":"json"}'), { 'content-type': 'application/json' })).toMatchObject({ status: 201, body: expect.stringContaining('"field":"json"') });
    expect(await send(Buffer.from('--bound\r\n'), { 'transfer-encoding': 'chunked' })).toMatchObject({ status: 400 });
  }, 30000);

  it('bounds highly fragmented chunked multipart input and accepts exact-cap payloads', async () => {
    const payload = multipart([Buffer.from([0, 1, 2, 255])]);
    const result = await sendFragmented(payload);
    expect(result.status).toBe(201);
    expect(result.body).toContain('000102ff');
    const emptyFileBody = multipart([Buffer.alloc(0)]);
    const exactCap = multipart([Buffer.alloc(64 * 1024 - emptyFileBody.length, 7)]);
    expect(exactCap.length).toBe(64 * 1024);
    expect((await sendFragmented(exactCap)).status).toBe(201);
    const overflow = await sendFragmented(Buffer.concat([payload, Buffer.alloc(64 * 1024)]));
    expect(overflow.status).toBe(413);
  }, 30000);

  it('retains request error handling through an under-limit client abort and serves a subsequent request', async () => {
    const uncaught: Error[] = [];
    const captureUncaught = (error: Error) => { uncaught.push(error); };
    process.on('uncaughtException', captureUncaught);
    try {
      const partial = createProbe('partial-abort');
      const partialRequest = openProbedRequest('partial-abort', { 'transfer-encoding': 'chunked' });
      const partialClientError = listenForClientError(partialRequest);
      partialRequest.write(Buffer.from('--bound\r\nContent-Disposition: form-data; name="field"\r\n\r\n'));
      await withinThreeSeconds(partial.firstData, 'partial upload first data');
      partialRequest.destroy();
      await withinThreeSeconds(partial.closed, 'partial upload close');
      expect(await withinThreeSeconds(partialClientError, 'partial client reset')).toBe('ECONNRESET');
      expect(partial.sawAborted).toBe(true);
      expect(partial.errors).toContain('ECONNRESET');

      expect((await withinThreeSeconds(send(multipart([Buffer.from('healthy')])))).status).toBe(201);
      expect(uncaught).toEqual([]);
    } finally {
      process.removeListener('uncaughtException', captureUncaught);
      probes.clear();
    }
  }, 15000);
});
