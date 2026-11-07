#!/usr/bin/env node
'use strict';

const { spawn, spawnSync } = require('node:child_process');
const { once } = require('node:events');
const { existsSync, readFileSync } = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { waitForReadiness } = require('./readiness.cjs');
const { validateTestDatabaseUrl } = require('../nest-backend/scripts/safe-prisma-db-push');

const root = path.resolve(__dirname, '..');
const backendDir = path.join(root, 'nest-backend');
const webDir = path.join(root, 'web');
const backendPort = 43187;
const webPort = 43188;

function validateEnvironment(env) {
  if (env.NODE_ENV !== 'test' || !validateTestDatabaseUrl(env.DATABASE_URL)) {
    throw new Error('Real web E2E requires NODE_ENV=test and the guarded local freebay_test_db');
  }
  const api = new URL(env.E2E_BACKEND_URL ?? 'http://127.0.0.1:43187');
  if (api.protocol !== 'http:' || !['127.0.0.1', 'localhost', '::1'].includes(api.hostname) ||
      api.port !== String(backendPort) || api.pathname !== '/') {
    throw new Error('Real web E2E API target must be the dedicated local test port');
  }
  const redis = new URL(env.REDIS_URL ?? '');
  if (redis.protocol !== 'redis:' || !['127.0.0.1', 'localhost', '::1'].includes(redis.hostname) ||
      redis.port !== '6379' || redis.pathname !== '/15') {
    throw new Error('Real web E2E requires the isolated local Redis database 15');
  }
  if (env.E2E_WEB_PORT !== String(webPort)) {
    throw new Error('Real web E2E requires the dedicated web test port');
  }
  for (const key of ['E2E_OUTPUT_DIR', 'E2E_SUMMARY_FILE']) {
    const destination = path.resolve(env[key] ?? '');
    const relative = path.relative(root, destination);
    if (!env[key] || relative === '' || (!relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative))) {
      throw new Error('Real web E2E output must stay outside the repository');
    }
    const tempRoot = path.resolve(os.tmpdir());
    const tempRelative = path.relative(tempRoot, destination);
    if (tempRelative === '..' || tempRelative.startsWith(`..${path.sep}`) || path.isAbsolute(tempRelative)) {
      throw new Error('Real web E2E output must stay in the system temporary directory');
    }
  }
  return { apiUrl: api.toString().replace(/\/$/, '') };
}

async function stopOwnedChild(child) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  const exited = once(child, 'exit');
  child.kill('SIGTERM');
  let timer;
  await Promise.race([
    exited,
    new Promise((resolve) => { timer = setTimeout(resolve, 10_000); }),
  ]);
  if (timer) clearTimeout(timer);
  if (child.exitCode === null && child.signalCode === null) {
    child.kill('SIGTERM');
    await once(child, 'exit');
  }
}

async function main() {
  const { apiUrl } = validateEnvironment(process.env);
  const backendEntry = path.join(backendDir, 'dist', 'src', 'main.js');
  const playwrightCli = path.join(webDir, 'node_modules', '@playwright', 'test', 'cli.js');
  if (!existsSync(backendEntry) || !existsSync(playwrightCli)) {
    throw new Error('Real web E2E build artifacts or Playwright installation are missing');
  }

  const backend = spawn(process.execPath, [backendEntry], {
    cwd: backendDir,
    env: { ...process.env, PORT: String(backendPort) },
    stdio: 'ignore',
  });
  backend.on('error', () => {});
  try {
    await waitForReadiness({
      baseUrl: apiUrl,
      timeoutMs: 120_000,
      onRetry: () => {
        if (backend.exitCode !== null) throw new Error('Backend process exited before dependency-aware readiness');
      },
    });
    const result = spawnSync(process.execPath, [playwrightCli, 'test', '--config=e2e/real-backend.config.ts'], {
      cwd: webDir,
      env: process.env,
      stdio: 'inherit',
      timeout: 600_000,
    });
    if (result.error) throw new Error('Real web Playwright process could not complete');
    if (result.status !== 0) process.exitCode = result.status ?? 1;

    const summaryPath = path.resolve(process.env.E2E_SUMMARY_FILE);
    const summary = JSON.parse(readFileSync(summaryPath, 'utf8'));
    if (summary.tests < 1 || summary.failed !== 0 || summary.skipped !== 0 || summary.success !== true) {
      throw new Error('Real web E2E did not produce a non-empty fully passing result');
    }
    process.stdout.write(`Safe E2E summary verified: tests=${summary.tests}, passed=${summary.passed}\n`);
  } finally {
    await stopOwnedChild(backend);
  }
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write(`${error instanceof Error ? error.message : 'Real web E2E failed'}\n`);
    process.exitCode = 1;
  });
}

module.exports = { validateEnvironment };
