import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { countText, isCounted } from './loc.mjs';

test('does not count the fictitious line after an EOF newline', () => {
  assert.deepEqual(countText('a\nb\n'), { physical: 2, code: 2 });
  assert.deepEqual(countText('a\nb'), { physical: 2, code: 2 });
  assert.deepEqual(countText(''), { physical: 0, code: 0 });
  assert.deepEqual(countText('\n'), { physical: 1, code: 0 });
  assert.deepEqual(countText('a\n\n'), { physical: 2, code: 1 });
});

test('recognizes CRLF and CR consistently', () => {
  assert.deepEqual(countText('one\r\ntwo\r\n'), { physical: 2, code: 2 });
  assert.deepEqual(countText('one\rtwo\r'), { physical: 2, code: 2 });
});

test('scope exclusion works with both slash conventions', () => {
  assert.equal(isCounted('features\\chat\\composer.tsx', 'web/app'), true);
  assert.equal(isCounted('features/chat/composer.test.tsx', 'web/app'), false);
  assert.equal(isCounted('modules\\orders\\use-case.ts', 'nest-backend/src'), true);
  assert.equal(isCounted('modules/orders/use-case.spec.ts', 'nest-backend/src'), false);
  assert.equal(isCounted('test\\fixtures.ts', 'nest-backend/src'), false);
});
