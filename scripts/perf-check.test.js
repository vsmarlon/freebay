const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { evaluate } = require('./perf-check');

const baseline = {
  thresholds: {
    p90_frame_build_ms: 8,
    worst_frame_build_ms: 32,
    p90_frame_rasterizer_ms: 8,
    worst_frame_rasterizer_ms: 32,
    missed_frame_budget_count: 0,
    regression_tolerance_pct: 20,
  },
  baseline: {
    '90th_percentile_frame_build_time_millis': 3,
    worst_frame_build_time_millis: 10,
    '90th_percentile_frame_rasterizer_time_millis': 3,
    worst_frame_rasterizer_time_millis: 10,
  },
};
const good = {
  average_frame_build_time_millis: 2,
  '90th_percentile_frame_build_time_millis': 3,
  worst_frame_build_time_millis: 10,
  missed_frame_build_budget_count: 0,
  average_frame_rasterizer_time_millis: 2,
  '90th_percentile_frame_rasterizer_time_millis': 3,
  worst_frame_rasterizer_time_millis: 10,
  missed_frame_rasterizer_budget_count: 0,
  frame_count: 80,
};

test('a real trace with both build and raster timings passes', () => {
  assert.deepEqual(evaluate(good, baseline), []);
});

test('missing frame metrics cannot be green', () => {
  assert.match(evaluate({ ...good, frame_count: 0 }, baseline).join(' '), /frame_count/);
  assert.match(evaluate({ ...good, worst_frame_rasterizer_time_millis: undefined }, baseline).join(' '), /rasterizer/);
});

test('raster jank fails even when build timings are fast', () => {
  const failures = evaluate({ ...good, missed_frame_rasterizer_budget_count: 2 }, baseline);
  assert.match(failures.join(' '), /rasterizer/);
});

test('20% regression from a measured baseline fails below the absolute threshold', () => {
  const failures = evaluate({ ...good, '90th_percentile_frame_build_time_millis': 3.7 }, baseline);
  assert.match(failures.join(' '), /baseline/);
});

test('absolute frame budgets fail at the boundary', () => {
  const failures = evaluate({ ...good, '90th_percentile_frame_build_time_millis': 8 }, baseline);
  assert.match(failures.join(' '), /build/);
});

function runCliWithReverseList(reverseList) {
  const source = fs.readFileSync(path.join(__dirname, 'perf-check.js'), 'utf8');
  const calls = [];
  const errors = [];
  const configuration = {
    thresholds: { p90_frame_build_ms: 8, worst_frame_build_ms: 32,
      p90_frame_rasterizer_ms: 8, worst_frame_rasterizer_ms: 32,
      missed_frame_budget_count: 0, regression_tolerance_pct: 20 },
    baseline: good, recorded_at: '2026-09-30T00:00:00Z',
    device: 'Test phone | android-arm64 | 1',
  };
  const fakeFs = {
    ...fs,
    existsSync: () => true,
    readFileSync: (file, encoding) => String(file).endsWith('feed_scroll.json')
      ? JSON.stringify(configuration) : '',
    rmSync() {}, mkdirSync() {}, writeFileSync() {},
  };
  const module = { exports: {} };
  const fakeRequire = (name) => {
    if (name === 'node:fs') return fakeFs;
    if (name === 'node:path') return path;
    if (name === 'node:child_process') return { spawnSync: (exe, args) => {
      calls.push([exe, ...args]);
      if (exe === 'flutter' && args[0] === 'devices') return { status: 0,
        stdout: JSON.stringify([{ id: 'phone', name: 'Test phone', targetPlatform: 'android-arm64', sdk: '1' }]), stderr: '' };
      if (exe === 'adb' && args.at(-1) === '--list') return reverseList;
      if (exe === 'flutter' && args[0] === 'drive') return { status: 1, stdout: '', stderr: 'controlled stop' };
      return { status: 0, stdout: '', stderr: '' };
    } };
    throw new Error(`unexpected require ${name}`);
  };
  fakeRequire.main = module;
  const context = { require: fakeRequire, module, exports: module.exports,
    __dirname: __dirname, __filename: path.join(__dirname, 'perf-check.js'),
    process: { platform: 'linux', argv: ['node', 'perf-check.js', 'feed_scroll', '--device', 'phone'],
      env: {}, stdout: { write() {} }, stderr: { write() {} }, exitCode: 0 },
    console: { log() {}, error: (message) => errors.push(String(message)) },
    Date, JSON, Number, Object, Array, String, RegExp, Error };
  vm.runInNewContext(source, context, { filename: 'perf-check.js' });
  return { calls, errors };
}

test('Android perf run preserves existing reverse to API port and leaves other mappings alone', () => {
  const result = runCliWithReverseList({ status: 0,
    stdout: 'UsbFfs tcp:3000 tcp:3110\nUsbFfs tcp:9000 tcp:9000\n', stderr: '' });
  assert.ok(result.calls.some((call) => call.includes('reverse') && call.at(-1) === '--list'));
  assert.ok(!result.calls.some((call) => call.includes('tcp:3000') && call.at(-1) !== '--list'));
  assert.ok(result.calls.some((call) => call.includes('drive')));
});

test('Android perf run adds the default reverse only when API port is unmapped', () => {
  const result = runCliWithReverseList({ status: 0,
    stdout: 'UsbFfs tcp:9000 tcp:9000\n', stderr: '' });
  assert.ok(result.calls.some((call) => call.includes('tcp:3000') && call.includes('reverse')));
  assert.ok(result.calls.some((call) => call.includes('drive')));
});

test('Android perf run fails closed when reverse inspection errors or fails', () => {
  for (const reverseList of [{ status: 1, stdout: '', stderr: 'adb unavailable' },
    { status: 0, error: new Error('spawn failed'), stdout: '', stderr: '' }]) {
    const result = runCliWithReverseList(reverseList);
    assert.ok(!result.calls.some((call) => call.includes('drive')));
    assert.ok(!result.calls.some((call) => call.includes('tcp:3000') && call.at(-1) !== '--list'));
    assert.ok(result.errors.some((message) => /reverse/.test(message)));
  }
});
