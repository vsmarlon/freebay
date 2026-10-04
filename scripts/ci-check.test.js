const assert = require('node:assert/strict');
const test = require('node:test');

const { checks, findLineViolations, checkRatchet, shrinkBaseline, designFindings, movedDesignBaselinePaths } = require('./ci-check');

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

test('design ratchet permits baseline findings and resolved findings but rejects additions', () => {
  const baseline = [
    { file: 'frontend/lib/features/feed.dart', rule: 'D1', specifier: 'ternary' },
  ];
  const current = [
    ...baseline,
    { file: 'frontend/lib/features/chat.dart', rule: 'D3', specifier: 'Colors.red' },
  ];

  assert.deepEqual(checkRatchet(current, baseline), {
    additions: [current[1]],
    resolved: [],
  });
  assert.deepEqual(checkRatchet([], baseline), {
    additions: [],
    resolved: baseline,
  });
  assert.equal(checkRatchet([...baseline, ...baseline], baseline).additions.length, 1);
  assert.throws(() => shrinkBaseline([...baseline, ...baseline], baseline), /cannot add findings/);
  assert.deepEqual(shrinkBaseline([], baseline), []);
});

test('design scanner catches only feature-level raw design tokens', () => {
  const findings = designFindings([
    'final color = isDark ? Colors.black : Colors.white;',
    'Text(style: TextStyle(',
    '  fontSize: 15,',
    '));',
    'const color = Color(0xff123456);',
    'const padding = EdgeInsets.all(12);',
    'const gap = SizedBox(height: 8);',
    'const transparent = Colors.transparent;',
    'final compact = isDark ? 1 : 2;',
    '// TextStyle(fontSize: 99)',
  ].join('\n'), 'frontend/lib/features/example.dart');

  assert.deepEqual(findings.map(({ rule }) => rule), ['D1', 'D3', 'D2', 'D4']);
});

test('design baseline keeps findings stable across completed feature moves', () => {
  assert.equal(
    movedDesignBaselinePaths.get('frontend/lib/features/stories/presentation/widgets/stories_row.dart'),
    'frontend/lib/features/social/presentation/widgets/stories_row.dart',
  );
  assert.equal(
    movedDesignBaselinePaths.get('frontend/lib/features/media_editor/presentation/pages/image_editor_page.dart'),
    'frontend/lib/features/chat/presentation/pages/image_editor_page.dart',
  );
});
