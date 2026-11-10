const assert = require('node:assert/strict');
const test = require('node:test');
const { waitForReadiness } = require('./readiness.cjs');

// HealthController.check() is wrapped by the existing TransformInterceptor;
// readiness() writes its own unwrapped JSON response through @Res().
const health = { status: 200, body: { success: true, data: { status: 'ok', service: 'freebay-backend' } } };
const healthy = { status: 200, body: { status: 'ready', checks: { database: 'healthy', redis: 'healthy' } } };
function fakeClock() {
  let value = 0;
  return {
    now: () => value,
    setTimer: (callback, ms) => { value += ms; callback(); return 0; },
  };
}

test('readiness requires FreeBay API identity plus healthy database and Redis', async () => {
  const clock = fakeClock();
  const result = await waitForReadiness({
    baseUrl: 'http://user:private@127.0.0.1:3000', now: clock.now, setTimer: clock.setTimer,
    request: async (url) => url.endsWith('/health')
      ? health
      : healthy,
  });
  assert.deepEqual(result.checks, { database: 'healthy', redis: 'healthy' });
});

test('wrong API identity fails immediately instead of accepting another open service', async () => {
  await assert.rejects(waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', request: async () => ({ status: 200, body: { success: true, data: { service: 'other-service' } } }),
  }), /API identity mismatch/);
  await assert.rejects(waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', request: async () => ({ status: 200, body: { service: 'freebay-backend' } }),
  }), /API identity mismatch/);
  await assert.rejects(waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', request: async () => ({ status: 404, body: null }),
  }), /API target mismatch/);
});

test('degraded dependencies retry and eventually succeed', async () => {
  const clock = fakeClock();
  let readyChecks = 0;
  const result = await waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', timeoutMs: 2_000, now: clock.now, setTimer: clock.setTimer,
    request: async (url) => {
      if (url.endsWith('/health')) return health;
      readyChecks += 1;
      return readyChecks < 3 ? { status: 503, body: { status: 'degraded' } } : healthy;
    },
  });
  assert.equal(result.checks.redis, 'healthy');
  assert.equal(readyChecks, 3);
});

test('unavailable endpoint has a bounded failure rather than accepting an open port', async () => {
  const clock = fakeClock();
  await assert.rejects(waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', timeoutMs: 1_000, now: clock.now, setTimer: clock.setTimer,
    request: async () => { throw new Error('connection refused'); },
  }), /timed out after 1000ms/);
});

test('readiness abort cancels a pending HTTP probe immediately', async () => {
  const controller = new AbortController();
  const pending = waitForReadiness({
    baseUrl: 'http://127.0.0.1:3000', signal: controller.signal,
    request: (_url, { signal }) => new Promise((_resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')), { once: true });
    }),
  });
  controller.abort();
  await assert.rejects(pending, /Readiness interrupted/);
});
