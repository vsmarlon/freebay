'use strict';

const assert = require('node:assert/strict');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const { validateEnvironment } = require('./run-real-web-e2e.cjs');

const temporary = path.join(os.tmpdir(), 'freebay-real-web-e2e-test');
const valid = {
  NODE_ENV: 'test',
  DATABASE_URL: 'postgresql://test:test@127.0.0.1:5432/freebay_test_db?schema=public',
  REDIS_URL: 'redis://127.0.0.1:6379/15',
  E2E_BACKEND_URL: 'http://127.0.0.1:43187',
  E2E_WEB_PORT: '43188',
  E2E_OUTPUT_DIR: path.join(temporary, 'artifacts'),
  E2E_SUMMARY_FILE: path.join(temporary, 'summary.json'),
};

test('accepts only the guarded test DB, isolated Redis DB, dedicated ports, and temp outputs', () => {
  assert.equal(validateEnvironment(valid).apiUrl, 'http://127.0.0.1:43187');
});

test('rejects runtime DB, Redis DB, and application ports', () => {
  for (const changed of [
    { DATABASE_URL: valid.DATABASE_URL.replace('freebay_test_db', 'postgres') },
    { REDIS_URL: 'redis://127.0.0.1:6379/0' },
    { E2E_BACKEND_URL: 'http://127.0.0.1:3000' },
    { E2E_WEB_PORT: '3000' },
  ]) assert.throws(() => validateEnvironment({ ...valid, ...changed }));
});

test('rejects result paths inside the repository', () => {
  const root = path.resolve(__dirname, '..');
  assert.throws(() => validateEnvironment({ ...valid, E2E_SUMMARY_FILE: path.join(root, 'summary.json') }));
});
