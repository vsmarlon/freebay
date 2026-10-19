const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { evaluate, validateDrawerCases, compareDrawerCases } = require('./perf-check');

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

function drawerResponse(frameSummary = good) {
  const labels = [
    ['header_tap', 'first_after_app_launch'], ['header_tap', 'repeat_same_process'],
    ['edge_right_drag', 'repeat_same_process'], ['edge_right_drag', 'repeat_same_process'],
    ['feed_content_right_drag', 'repeat_same_process'], ['feed_content_right_drag', 'repeat_same_process'],
  ];
  const response = { drawer_native_input_latency: 'unsupported' };
  response.drawer_cases = labels.map(([interaction, opening], index) => {
    const key = `drawer_case_${index}`;
    response[key] = { ...frameSummary };
    return { interaction, opening, open: true, frame_report_key: key,
      ...(index >= 2 ? { cold_status: 'pending_separate_profile_launch' } : {}) };
  });
  return response;
}

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

function runCli({ updateBaseline = false, summary = good, driveStatus = 1,
  flow = 'feed_scroll', responseData } = {}) {
  responseData ??= { performance: summary };
  const source = fs.readFileSync(path.join(__dirname, 'perf-check.js'), 'utf8');
  const calls = [];
  const errors = [];
  const baselineWrites = [];
  const configuration = {
    thresholds: { p90_frame_build_ms: 8, worst_frame_build_ms: 32,
      p90_frame_rasterizer_ms: 8, worst_frame_rasterizer_ms: 32,
      missed_frame_budget_count: 0, regression_tolerance_pct: 20 },
    baseline: flow === 'drawer_open' ? null : good,
    drawer_cases: flow === 'drawer_open' ? null : undefined,
    recorded_at: flow === 'drawer_open' ? null : '2026-09-30T00:00:00Z',
    device: 'Test phone | android-arm64 | 1',
  };
  const fakeFs = {
    ...fs,
    existsSync: () => true,
    readFileSync: (file) => {
      if (String(file).endsWith(`${flow}.json`)) return JSON.stringify(configuration);
      if (String(file).endsWith('integration_response_data.json')) {
        return JSON.stringify(responseData);
      }
      return '';
    },
    rmSync() {}, mkdirSync() {}, writeFileSync(file, contents) {
      if (String(file).endsWith(`${flow}.json`)) baselineWrites.push(String(contents));
    },
  };
  const module = { exports: {} };
  const fakeRequire = (name) => {
    if (name === 'node:fs') return fakeFs;
    if (name === 'node:path') return path;
    if (name === 'node:child_process') return { spawnSync: (exe, args) => {
      calls.push([exe, ...args]);
      if (exe === 'flutter' && args[0] === 'devices') return { status: 0,
        stdout: JSON.stringify([{ id: 'phone', name: 'Test phone', targetPlatform: 'android-arm64', sdk: '1' }]), stderr: '' };
      if (exe === 'flutter' && args[0] === 'drive') return { status: driveStatus, stdout: '', stderr: '' };
      return { status: 0, stdout: '', stderr: '' };
    } };
    throw new Error(`unexpected require ${name}`);
  };
  fakeRequire.main = module;
  const context = { require: fakeRequire, module, exports: module.exports,
    __dirname: __dirname, __filename: path.join(__dirname, 'perf-check.js'),
    process: { platform: 'linux', argv: ['node', 'perf-check.js', flow, '--device', 'phone',
      ...(updateBaseline ? ['--update-baseline'] : [])],
      env: {}, stdout: { write() {} }, stderr: { write() {} }, exitCode: 0 },
    console: { log() {}, error: (message) => errors.push(String(message)) },
    Date, JSON, Number, Object, Array, String, RegExp, Error };
  vm.runInNewContext(source, context, { filename: 'perf-check.js' });
  return { calls, errors, baselineWrites, configuration, exitCode: context.process.exitCode };
}

test('perf driver loads the local env file and never changes adb mappings', () => {
  const result = runCli();
  assert.ok(result.calls.some((call) => call.includes('drive') && call.includes('--dart-define-from-file=.env')));
  assert.ok(!result.calls.some((call) => call.includes('adb') || call.includes('reverse')));
});

test('drawer requires successful cold/warm labels and build/raster timings for every input', () => {
  const response = drawerResponse();
  assert.deepEqual(validateDrawerCases(response.drawer_cases, response), []);
  delete response.drawer_case_0.worst_frame_rasterizer_time_millis;
  assert.match(validateDrawerCases(response.drawer_cases, response).join(' '), /rasterizer/);
  assert.match(validateDrawerCases(response.drawer_cases.slice(1), response).join(' '), /incomplete/);
  response.drawer_cases[0].opening = 'repeat_same_process';
  assert.match(validateDrawerCases(response.drawer_cases, response).join(' '), /expected outcome\/label/);
});

test('per-interaction frame regressions are compared to that interaction baseline', () => {
  const response = drawerResponse();
  const prior = response.drawer_cases.map((item, index) => ({ ...item,
    frame_summary: index === 0 ? good : { ...good, worst_frame_build_time_millis: 10 },
  }));
  response.drawer_case_0 = { ...good, '90th_percentile_frame_build_time_millis': 4 };
  assert.match(compareDrawerCases(response.drawer_cases, response, prior, baseline).join(' '), /regressed/);
});

test('failed absolute or relative measurements do not replace a healthy baseline', () => {
  for (const summary of [
    { ...good, '90th_percentile_frame_build_time_millis': 8 },
    { ...good, '90th_percentile_frame_build_time_millis': 3.7 },
  ]) {
    const result = runCli({ updateBaseline: true, summary, driveStatus: 0 });
    assert.equal(result.exitCode, 1);
    assert.deepEqual(result.baselineWrites, []);
    assert.equal(result.configuration.baseline['90th_percentile_frame_build_time_millis'], 3);
  }
});

test('a measured passing trace may replace the baseline', () => {
  const result = runCli({ updateBaseline: true, driveStatus: 0 });
  assert.equal(result.exitCode, 0, result.errors.join('\n'));
  assert.equal(result.baselineWrites.length, 1);
  assert.equal(JSON.parse(result.baselineWrites[0]).baseline['90th_percentile_frame_build_time_millis'], 3);
});

test('drawer baseline records only when all per-input frame budgets pass', () => {
  const clean = runCli({ flow: 'drawer_open', updateBaseline: true,
    driveStatus: 0, responseData: drawerResponse() });
  assert.equal(clean.exitCode, 0, clean.errors.join('\n'));
  assert.equal(clean.baselineWrites.length, 1);
  assert.equal(JSON.parse(clean.baselineWrites[0]).drawer_cases.length, 6);

  const red = drawerResponse({ ...good, '90th_percentile_frame_build_time_millis': 8 });
  const failed = runCli({ flow: 'drawer_open', updateBaseline: true, driveStatus: 0,
    responseData: red });
  assert.equal(failed.exitCode, 1);
  assert.deepEqual(failed.baselineWrites, []);
});
