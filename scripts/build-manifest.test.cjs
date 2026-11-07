'use strict';

const assert = require('node:assert/strict');
const { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

test('build manifest digest is stable and changes when artifact content changes', () => {
  const temporary = mkdtempSync(path.join(os.tmpdir(), 'freebay-manifest-'));
  try {
    const artifact = path.join(temporary, 'build');
    mkdirSync(path.join(artifact, 'nested'), { recursive: true });
    writeFileSync(path.join(artifact, 'nested', 'app.js'), 'synthetic artifact');
    const manifest = path.join(temporary, 'manifest.json');
    const verification = path.join(temporary, 'verification.json');
    writeFileSync(verification, JSON.stringify({ tests: 1, failed: 0, skipped: 0, success: true }));
    const script = path.join(__dirname, 'build-manifest.cjs');
    const run = (action) => spawnSync(process.execPath, [script, action, artifact, manifest, 'revision-1', 'test-config', verification], { encoding: 'utf8' });

    assert.equal(run('create').status, 0);
    const created = JSON.parse(readFileSync(manifest, 'utf8'));
    assert.equal(run('verify').status, 0);
    writeFileSync(path.join(artifact, 'nested', 'app.js'), 'changed artifact');
    const mismatch = run('verify');
    assert.notEqual(mismatch.status, 0);
    assert.match(mismatch.stderr, /manifest mismatch/);
    assert.equal(created.fileCount, 1);
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});
