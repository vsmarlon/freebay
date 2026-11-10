const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const test = require('node:test');

const { checks, findLineViolations, checkRatchet, shrinkBaseline, designFindings, movedDesignBaselinePaths, boundaryFindings } = require('./ci-check');

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

test('boundary scanner detects aliased, relative and type-only violations, but not comments or strings', () => {
  const findings = boundaryFindings([
    { file: 'nest-backend/src/modules/alpha/usecases/x.ts', content: [
      "import type { X } from '@/modules/beta/data/x';",
      "export { Y } from '../../beta/services/y';",
      "// import { Z } from '@/modules/beta/usecases/z';",
      "const text = \"import('@/modules/beta/data/x')\";",
    ].join('\n') },
    { file: 'frontend/lib/features/auth/domain/x.dart', content: "// import '../data/repositories/x.dart';\nimport '../data/repositories/x.dart';" },
  ]);
  assert.deepEqual(findings.map(({ rule }) => rule), ['F1', 'B1', 'B1']);
});

test('boundary ratchet rejects additions and permits only shrinking', () => {
  const existing = { file: 'a.ts', specifier: 'x', rule: 'B1' };
  const added = { file: 'b.ts', specifier: 'y', rule: 'B2' };
  assert.deepEqual(checkRatchet([existing, added], [existing]).additions, [added]);
  assert.deepEqual(shrinkBaseline([], [existing]), []);
  assert.throws(() => shrinkBaseline([added], []), /cannot add findings/);
});

test('backend boundaries ban @prisma/client in business roles and keep domain framework-free (B4/B5)', () => {
  const findings = boundaryFindings([
    { file: 'nest-backend/src/modules/orders/data/repositories/order.repository.ts', content: "import { Prisma } from '@prisma/client';" },
    { file: 'nest-backend/src/modules/orders/order-status.controller.ts', content: "import * as Prisma from '@prisma/client';" },
    { file: 'nest-backend/src/modules/orders/usecases/checkout.ts', content: [
      "import { PrismaClient } from '@prisma/client';",
      "import type { Address } from '@prisma/client/runtime/library';",
    ].join('\n') },
    { file: 'nest-backend/src/modules/reviews/domain/policy.ts', content: [
      "import { Injectable } from '@nestjs/common';",
      "import type { User } from '@prisma/client';",
    ].join('\n') },
    { file: 'nest-backend/src/modules/wallet/domain/wallet.repository.ts', content: "import { TransactionClient } from '@prisma/client';" },
    { file: 'nest-backend/src/shared/infra/prisma/client.ts', content: "import { PrismaClient } from '@prisma/client';" },
  ]);
  assert.deepEqual(findings.map(({ rule }) => rule), ['B4', 'B4', 'B4', 'B5', 'B5', 'B5'], JSON.stringify(findings));
});

test('backend boundaries distinguish PrismaService and Repository imports from allowed contracts', () => {
  const findings = boundaryFindings([
    { file: 'nest-backend/src/modules/orders/usecases/do.ts', content: [
      "import { PrismaService } from '@/shared/infra/prisma/prisma.service';",
      "import type { RepositoryResponse } from '@/shared/core/repository-response';",
    ].join('\n') },
    { file: 'nest-backend/src/modules/orders/orders.controller.ts', content: [
      "import type { OrderRepository } from './data/repositories/order.repository';",
      "import type { RepositoryResponse } from '@/shared/core/repository-response';",
    ].join('\n') },
    { file: 'nest-backend/src/modules/orders/orders.controller.ts', content: "import * as Repositories from './data/repositories';" },
    { file: 'nest-backend/src/modules/orders/default.controller.ts', content: "import OrderRepository from './data/repositories/order.repository';" },
    { file: 'nest-backend/src/modules/orders/public.controller.ts', content: "import { OrderRepository as Orders } from './public';" },
    { file: 'nest-backend/src/modules/orders/import-equals.controller.ts', content: "import Orders = require('./data/repositories/order.repository');" },
    { file: 'nest-backend/src/modules/orders/root.service.ts', content: "import * as Prisma from '@/shared/infra/prisma/prisma.service';" },
    { file: 'nest-backend/src/modules/orders/health.service.ts', content: "import { PrismaService } from '@/shared/infra/prisma/prisma.service';" },
    { file: 'nest-backend/src/modules/orders/foo.controller.ts', content: "import { PrismaService as Database } from '@/shared/infra/prisma/prisma.service';" },
    { file: 'nest-backend/src/modules/orders/data/repositories/order.repository.ts', content: "import { PrismaService } from '@/shared/infra/prisma/prisma.service';" },
    { file: 'nest-backend/src/modules/tasks/tasks.module.ts', content: "import { PrismaService } from '@/shared/infra/prisma/prisma.service';" },
    { file: 'nest-backend/src/modules/health/health.controller.ts', content: "import { PrismaService } from '@/shared/infra/prisma/prisma.service';" },
  ]);
  assert.deepEqual(findings.map(({ rule }) => rule), ['B3', 'B2', 'B2', 'B3', 'B3', 'B3', 'B3', 'B2', 'B2'], JSON.stringify(findings));
});

test('Dart boundary directives resolve imports, exports and conditional URIs without matching comments or strings', () => {
  const findings = boundaryFindings([
    { file: 'frontend/lib/features/auth/domain/flow.dart', content: [
      "import 'package:freebay/features/auth/data/repositories/auth_repository.dart';",
      "export '../data/repositories/auth_repository.dart';",
      "import 'package:freebay/features/auth/data/repositories/../entities/user.dart';",
      "// import '../data/repositories/ignored.dart';",
      "/* export '../data/repositories/ignored.dart'; */",
      "const example = \"import '../data/repositories/ignored.dart';\";",
    ].join('\n') },
    { file: 'frontend/lib/core/bridge.dart', content: [
      "import 'package:freebay/features/auth/domain/model.dart' if (dart.library.io) '../features/auth/data/entity.dart';",
      "export '../features/social/presentation/page.dart';",
      "const example = '''import '../features/chat/presentation/page.dart';''';",
    ].join('\n') },
  ]);
  assert.deepEqual(findings.map(({ rule, specifier }) => [rule, specifier]), [
    ['F2', '../features/auth/data/entity.dart'],
    ['F2', '../features/social/presentation/page.dart'],
    ['F2', 'package:freebay/features/auth/domain/model.dart'],
    ['F1', '../data/repositories/auth_repository.dart'],
    ['F1', 'package:freebay/features/auth/data/repositories/auth_repository.dart'],
  ]);
});

function runBoundaryCli({ files = {}, baseline = [], designBaseline = [], args = ['--boundaries'], omitBaseline = false } = {}) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'freebay-ci-boundaries-'));
  try {
    fs.mkdirSync(path.join(directory, 'scripts'), { recursive: true });
    fs.copyFileSync(path.join(__dirname, 'ci-check.js'), path.join(directory, 'scripts/ci-check.js'));
    if (!omitBaseline) fs.writeFileSync(path.join(directory, 'scripts/boundaries-baseline.json'), `${JSON.stringify(baseline)}\n`);
    fs.writeFileSync(path.join(directory, 'scripts/design-baseline.json'), `${JSON.stringify(designBaseline)}\n`);
    const typeScriptPath = path.dirname(require.resolve(path.join(root, 'nest-backend/node_modules/typescript/package.json')));
    fs.mkdirSync(path.join(directory, 'nest-backend/node_modules'), { recursive: true });
    fs.cpSync(typeScriptPath, path.join(directory, 'nest-backend/node_modules/typescript'), { recursive: true });
    for (const [file, content] of Object.entries(files)) {
      const target = path.join(directory, file);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, content);
    }
    const result = spawnSync(process.execPath, [path.join(directory, 'scripts/ci-check.js'), ...args], { encoding: 'utf8' });
    return { ...result, baseline: fs.existsSync(path.join(directory, 'scripts/boundaries-baseline.json'))
      ? JSON.parse(fs.readFileSync(path.join(directory, 'scripts/boundaries-baseline.json'), 'utf8')) : null };
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

test('boundary CLI default gate, missing baseline, growth, shrink and rename ratchet behave end to end', () => {
  const violation = { 'nest-backend/src/modules/a/usecases/x.ts': "import { X } from '@/modules/b/data/x';" };
  const known = { file: 'nest-backend/src/modules/a/usecases/x.ts', specifier: '@/modules/b/data/x', rule: 'B1' };
  assert.notEqual(runBoundaryCli({ files: violation, args: [] }).status, 0);
  const knownPass = runBoundaryCli({ files: violation, baseline: [known], args: [] });
  assert.equal(knownPass.status, 0, `${knownPass.stderr}${knownPass.stdout}`);
  const missing = runBoundaryCli({ files: violation, args: ['--boundaries'], omitBaseline: true });
  assert.notEqual(missing.status, 0);
  assert.equal(missing.baseline, null);
  const growth = runBoundaryCli({ files: violation, baseline: [], args: ['--boundaries', '--update-baseline'] });
  assert.notEqual(growth.status, 0);
  assert.deepEqual(growth.baseline, []);
  const shrink = runBoundaryCli({ files: {}, baseline: [known], args: ['--boundaries', '--update-baseline'] });
  assert.equal(shrink.status, 0);
  assert.deepEqual(shrink.baseline, []);
  const renamed = { 'nest-backend/src/modules/a/usecases/renamed.ts': "import { X } from '@/modules/b/data/x';" };
  assert.notEqual(runBoundaryCli({ files: renamed, baseline: [known] }).status, 0);
  assert.notEqual(runBoundaryCli({ files: {}, baseline: [], args: ['--boundaries', '--architecture'] }).status, 0);
  assert.equal(runBoundaryCli({ files: {}, baseline: [], args: ['--architecture', '--routes', '--design'] }).status, 0);
  assert.equal(runBoundaryCli({ files: {}, baseline: [], designBaseline: [
    { file: 'frontend/lib/features/x.dart', specifier: 'Colors.red', rule: 'D3' },
  ], args: ['--update-baseline'] }).status, 0);
});
