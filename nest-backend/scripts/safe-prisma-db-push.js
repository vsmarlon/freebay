const { spawnSync } = require('node:child_process');

const TEST_DATABASE = 'freebay_test_db';
const ALLOWED_HOSTS = new Set(['localhost', '127.0.0.1', '::1']);
const ALLOWED_PORTS = new Set(['5432', '5433']);

function validateTestDatabaseUrl(value) {
  if (!value) return false;

  try {
    const url = new URL(value);
    const hostname = url.hostname.replace(/^\[|\]$/g, '');
    return (
      (url.protocol === 'postgres:' || url.protocol === 'postgresql:') &&
      url.pathname === `/${TEST_DATABASE}` &&
      ALLOWED_HOSTS.has(hostname) &&
      ALLOWED_PORTS.has(url.port || '5432') &&
      !url.searchParams.has('url')
    );
  } catch {
    return false;
  }
}

function run({ env = process.env, spawn = spawnSync } = {}) {
  if (env.NODE_ENV !== 'test') {
    console.error('Refusing Prisma schema sync: NODE_ENV must be test.');
    return 1;
  }

  if (!validateTestDatabaseUrl(env.DATABASE_URL)) {
    console.error(`Refusing Prisma schema sync: DATABASE_URL must target local ${TEST_DATABASE}.`);
    return 1;
  }

  let result;
  try {
    result = spawn(process.execPath, [
      require.resolve('prisma/build/index.js'),
      'db',
      'push',
      '--accept-data-loss',
    ], { env, stdio: 'inherit' });
  } catch {
    console.error('Prisma schema sync could not start.');
    return 1;
  }

  if (result.error) {
    console.error('Prisma schema sync could not start.');
    return 1;
  }
  return result.status ?? 1;
}

if (require.main === module) process.exitCode = run();

module.exports = { TEST_DATABASE, run, validateTestDatabaseUrl };
