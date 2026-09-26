const assert = require('node:assert/strict');
const test = require('node:test');

const { checks, findLineViolations } = require('./ci-check');

test('architecture gate rejects removed safe identifiers only', () => {
  const source = [
    'return safeCall(value);',
    'return safeGet(value);',
    'return safeRun(value);',
    '@Get("/items")',
    '@Post("/items")',
    'class SafeArea {}',
    'const url = "https://example.test/safeRun";',
    'const script = "safeRun.js";',
    'safe-prisma-db-push.js',
  ].join('\n');
  const violations = findLineViolations(source, checks.architecture);

  assert.deepEqual(violations.map((violation) => violation.split(': ')[1]), [
    'return safeCall(value);',
    'return safeGet(value);',
    'return safeRun(value);',
  ]);
});

test('architecture gate still detects removed repository identifiers in imports', () => {
  const violations = findLineViolations(
    "import { BaseHttpRepository } from './base_http_repository';",
    checks.architecture,
  );

  assert.equal(violations.length, 1);
});

test('route and design gates keep their existing policy', () => {
  assert.match("context.go('/feed')", checks.routes[0]);
  assert.match("route: '/notifications'", checks.routes[1]);
  assert.doesNotMatch('route: AppRoutes.notifications', checks.routes[1]);
  assert.match('BorderRadius.circular(4)', checks.design[0]);
  assert.doesNotMatch('BorderRadius.zero', checks.design[0]);
});
