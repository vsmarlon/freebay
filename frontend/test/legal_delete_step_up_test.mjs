import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

test('web account deletion requires password step-up and sends its token only to deletion', async () => {
  const html = await readFile(
    process.env.DELETE_ACCOUNT_HTML ?? new URL('../../nest-backend/legal/delete-account.html', import.meta.url),
    'utf8',
  );
  const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
  assert.ok(script);
  const elements = new Map();
  for (const id of ['status', 'request-form', 'authenticated', 'confirm', 'delete-button', 'cancel-button', 'auth-status', 'password', 'step-up-proof', 'confirm-label']) {
    elements.set(id, { value: '', checked: false, hidden: false, disabled: false, textContent: '', listeners: {}, addEventListener(name, callback) { this.listeners[name] = callback; } });
  }
  const calls = [];
  const responses = [
    { data: { user: {} } },
    { data: { stepUpToken: 'fresh-proof' } },
    { data: { deletionRequestedAt: '2026-10-05T12:00:00.000Z' } },
  ];
  const context = {
    document: { getElementById: id => elements.get(id) },
    window: { location: { hash: '#token=magic', pathname: '/legal/delete-account', search: '' }, history: { replaceState() {} } },
    URLSearchParams,
    Date,
    fetch: async (path, options) => {
      calls.push({ path, options });
      return { ok: true, status: 200, text: async () => JSON.stringify(responses.shift()) };
    },
  };
  vm.runInNewContext(script, context);
  await new Promise(resolve => setImmediate(resolve));
  elements.get('confirm').checked = true;
  elements.get('password').value = 'correct horse battery';
  await elements.get('delete-button').listeners.click();

  assert.deepEqual(calls.map(call => call.path), ['/auth/web/magic-link/consume', '/auth/web/step-up', '/users/me/web']);
  assert.deepEqual(JSON.parse(calls[1].options.body), {
    purpose: 'delete_account', proof: { kind: 'password', password: 'correct horse battery' },
  });
  assert.equal(calls[2].options.headers['x-step-up-token'], 'fresh-proof');
  assert.equal(calls[2].options.credentials, 'same-origin');
});
