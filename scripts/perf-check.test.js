const test = require('node:test');
const assert = require('node:assert/strict');
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
