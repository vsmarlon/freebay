const DEFAULT_TIMEOUT_MS = 120_000;
const RETRY_MS = 400;
const REQUEST_TIMEOUT_MS = 1_500;

function delay(ms, setTimer = setTimeout, signal) {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) return reject(new Error('Readiness interrupted.'));
    let timer;
    const onAbort = () => {
      clearTimeout(timer);
      reject(new Error('Readiness interrupted.'));
    };
    timer = setTimer(() => {
      signal?.removeEventListener('abort', onAbort);
      resolve();
    }, ms);
    signal?.addEventListener('abort', onAbort, { once: true });
  });
}

function requestSignal(ms, signal) {
  const timeout = AbortSignal.timeout(ms);
  return signal ? AbortSignal.any([signal, timeout]) : timeout;
}

async function requestJson(url, { signal } = {}) {
  const response = await fetch(url, { signal });
  let body;
  try {
    body = await response.json();
  } catch {
    body = null;
  }
  return { status: response.status, body };
}

function healthService(body) {
  if (body?.success !== true || body?.data?.service !== 'freebay-backend') {
    throw new Error('API identity mismatch: expected FreeBay health envelope for freebay-backend.');
  }
  return body.data.service;
}

async function waitForReadiness({
  baseUrl,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  request = requestJson,
  onRetry,
  now = Date.now,
  setTimer = setTimeout,
  signal,
} = {}) {
  if (!baseUrl) throw new Error('Readiness requires an API base URL.');
  const origin = new URL(baseUrl);
  if (!['http:', 'https:'].includes(origin.protocol)) throw new Error('Readiness API URL must use HTTP or HTTPS.');
  origin.username = '';
  origin.password = '';
  const base = origin.origin;
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) throw new Error('Readiness timeout must be a positive number of milliseconds.');
  const deadline = now() + timeoutMs;
  let attempt = 0;

  while (now() <= deadline) {
    if (signal?.aborted) throw new Error('Readiness interrupted.');
    attempt += 1;
    try {
      const health = await request(`${base}/health`, {
        signal: requestSignal(Math.min(REQUEST_TIMEOUT_MS, Math.max(1, deadline - now())), signal),
      });
      if (health.status !== 200 && health.status !== 503) {
        throw new Error('API target mismatch: /health is not the expected FreeBay endpoint.');
      }
      const service = health.status === 200 ? healthService(health.body) : null;
      if (health.status === 200) {
        const ready = await request(`${base}/health/ready`, {
          signal: requestSignal(Math.min(REQUEST_TIMEOUT_MS, Math.max(1, deadline - now())), signal),
        });
        const checks = ready.body?.checks;
        if (ready.status === 200 && ready.body?.status === 'ready' &&
            checks?.database === 'healthy' && checks?.redis === 'healthy') {
          return { service, checks };
        }
      }
    } catch (error) {
      if (signal?.aborted) throw new Error('Readiness interrupted.');
      if (error.message.startsWith('API identity mismatch:') || error.message.startsWith('API target mismatch:')) throw error;
    }

    if (now() >= deadline) break;
    onRetry?.(attempt);
    await delay(Math.min(RETRY_MS, deadline - now()), setTimer, signal);
  }
  throw new Error(`API readiness timed out after ${timeoutMs}ms (API, database, and Redis must be ready).`);
}

if (require.main === module) {
  const baseUrl = process.argv[2] || 'http://127.0.0.1:3000';
  const timeoutMs = Number(process.argv[3] || DEFAULT_TIMEOUT_MS);
  waitForReadiness({ baseUrl, timeoutMs })
    .then(() => console.log('[FreeBay] API, database, and Redis are ready.'))
    .catch((error) => {
      console.error(`[FreeBay] ${error.message}`);
      process.exitCode = 1;
    });
}

module.exports = { DEFAULT_TIMEOUT_MS, healthService, waitForReadiness };
