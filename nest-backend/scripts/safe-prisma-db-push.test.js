const assert = require('node:assert/strict');
const { spawnSync: spawnEntrypoint } = require('node:child_process');
const test = require('node:test');
const { run, validateTestDatabaseUrl } = require('./safe-prisma-db-push');

test('rejects a non-test environment before spawning Prisma', () => {
  let spawned = false;

  const status = run({
    env: { NODE_ENV: 'development', DATABASE_URL: 'postgresql://user:pass@localhost:5432/freebay_test_db' },
    spawn: () => {
      spawned = true;
      return { status: 0 };
    },
  });

  assert.equal(status, 1);
  assert.equal(spawned, false);
});

test('the entrypoint rejects a non-test environment', () => {
  const result = spawnEntrypoint(process.execPath, [__dirname + '/safe-prisma-db-push.js'], {
    env: { ...process.env, NODE_ENV: 'development', DATABASE_URL: 'postgresql://user:pass@localhost:5432/freebay_test_db' },
    encoding: 'utf8',
  });

  assert.equal(result.status, 1);
  assert.match(result.stderr, /NODE_ENV must be test/);
  assert.doesNotMatch(result.stderr, /user|pass|freebay_test_db/);
});

test('accepts only the local test database URL', () => {
  assert.equal(validateTestDatabaseUrl('postgresql://test:test@[::1]:5433/freebay_test_db?schema=public'), true);
  assert.equal(validateTestDatabaseUrl('postgresql://test:test@remote:5432/freebay_test_db'), false);
  assert.equal(validateTestDatabaseUrl('postgresql://test:test@localhost:5432/freebay'), false);
  assert.equal(validateTestDatabaseUrl('mysql://test:test@localhost:5432/freebay_test_db'), false);
  assert.equal(validateTestDatabaseUrl('postgresql://test:test@localhost:5434/freebay_test_db'), false);
  assert.equal(validateTestDatabaseUrl('not-a-url'), false);
  assert.equal(validateTestDatabaseUrl('postgresql://test:test@localhost:5432/freebay_test_db?url=postgresql://remote/other'), false);
});

test('does not allow CLI arguments to override the validated target', () => {
  let options;

  const status = run({
    env: { NODE_ENV: 'test', DATABASE_URL: 'postgresql://user:pass@localhost:5432/freebay_test_db' },
    spawn: (_command, args, childOptions) => {
      assert.deepEqual(args.slice(1), ['db', 'push', '--accept-data-loss']);
      options = childOptions;
      return { status: 0 };
    },
  });

  assert.equal(status, 0);
  assert.equal(options.env.NODE_ENV, 'test');
});

test('returns a generic failure when Prisma cannot spawn', () => {
  const status = run({
    env: { NODE_ENV: 'test', DATABASE_URL: 'postgresql://user:pass@localhost:5432/freebay_test_db' },
    spawn: () => ({ status: null, error: new Error('private spawn detail') }),
  });

  assert.equal(status, 1);
});
