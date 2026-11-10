#!/usr/bin/env node
// Profile-mode device frame budget gate. See .agents/skills/freebay-perf/SKILL.md.
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const frontend = path.join(root, 'frontend');
const metrics = [
  'average_frame_build_time_millis',
  '90th_percentile_frame_build_time_millis',
  'worst_frame_build_time_millis',
  'missed_frame_build_budget_count',
  'average_frame_rasterizer_time_millis',
  '90th_percentile_frame_rasterizer_time_millis',
  'worst_frame_rasterizer_time_millis',
  'missed_frame_rasterizer_budget_count',
  'frame_count',
];
const limits = [
  ['90th_percentile_frame_build_time_millis', 'p90_frame_build_ms'],
  ['worst_frame_build_time_millis', 'worst_frame_build_ms'],
  ['90th_percentile_frame_rasterizer_time_millis', 'p90_frame_rasterizer_ms'],
  ['worst_frame_rasterizer_time_millis', 'worst_frame_rasterizer_ms'],
];

function validateSummary(summary, minimumFrames = 30) {
  const failures = [];
  for (const name of metrics) {
    const value = summary?.[name];
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 ||
        (name.endsWith('_count') || name === 'frame_count') && !Number.isInteger(value)) {
      failures.push(`${name} missing or invalid`);
    }
  }
  if (typeof summary?.frame_count === 'number' && summary.frame_count < minimumFrames) {
    failures.push(`frame_count below ${minimumFrames}: interaction was not measured`);
  }
  return failures;
}

function evaluate(summary, config, { minimumFrames = 30, baseline = config.baseline } = {}) {
  const failures = validateSummary(summary, minimumFrames);
  if (failures.length) return failures;

  for (const [metric, threshold] of limits) {
    const max = config.thresholds[threshold];
    if (summary[metric] >= max) failures.push(`${metric} ${summary[metric]}ms >= ${max}ms`);
    const prior = baseline?.[metric];
    if (typeof prior === 'number' && summary[metric] > prior *
        (1 + config.thresholds.regression_tolerance_pct / 100)) {
      failures.push(`${metric} ${summary[metric]}ms regressed against baseline ${prior}ms`);
    }
  }
  for (const metric of ['missed_frame_build_budget_count', 'missed_frame_rasterizer_budget_count']) {
    if (summary[metric] > config.thresholds.missed_frame_budget_count) {
      failures.push(`${metric} ${summary[metric]} exceeds ${config.thresholds.missed_frame_budget_count}`);
    }
  }
  return failures;
}

function validateDrawerCases(cases, responseData) {
  if (!Array.isArray(cases) || cases.length !== 6) {
    return ['drawer_cases missing or incomplete (expected six labeled interactions)'];
  }
  const failures = [];
  const expected = [
    ['header_tap', 'first_after_app_launch'],
    ['header_tap', 'repeat_same_process'],
    ['edge_right_drag', 'repeat_same_process'],
    ['edge_right_drag', 'repeat_same_process'],
    ['feed_content_right_drag', 'repeat_same_process'],
    ['feed_content_right_drag', 'repeat_same_process'],
  ];
  for (const [index, item] of cases.entries()) {
    if (item?.interaction !== expected[index][0] || item?.opening !== expected[index][1] ||
        item?.open !== true || typeof item.frame_report_key !== 'string') {
      failures.push(`drawer case ${index + 1} missing expected outcome/label/frame key`);
    }
    const frameFailures = validateSummary(responseData?.[item?.frame_report_key], 1);
    if (frameFailures.length) failures.push(`drawer case ${index + 1}: ${frameFailures.join(', ')}`);
  }
  for (const interaction of ['header_tap', 'edge_right_drag', 'feed_content_right_drag']) {
    const rows = cases.filter((item) => item?.interaction === interaction);
    if (rows.length !== 2) failures.push(`${interaction} did not produce two labeled opens`);
  }
  if (cases.slice(2).some((item) => item.cold_status !== 'pending_separate_profile_launch'))
    failures.push('drawer cold cases not run must be marked pending');
  return failures;
}

function compareDrawerCases(cases, responseData, previous, config) {
  if (!Array.isArray(previous) || previous.length !== 6) return [];
  const failures = [];
  for (const [index, item] of cases.entries()) {
    const current = responseData[item.frame_report_key];
    const prior = previous[index]?.frame_summary;
    for (const [metric] of limits) {
      if (typeof prior?.[metric] === 'number' && current[metric] >
          prior[metric] * (1 + config.thresholds.regression_tolerance_pct / 100)) {
        failures.push(`${item.interaction} ${item.opening}: ${metric} ${current[metric]}ms regressed against baseline ${prior[metric]}ms`);
      }
    }
  }
  return failures;
}

function command(executable, args, cwd = root) {
  // On Windows, Flutter is a .bat wrapper: spawnSync('flutter') returns ENOENT.
  const windows = process.platform === 'win32' && executable === 'flutter';
  return spawnSync(windows ? 'cmd.exe' : executable,
    windows ? ['/d', '/s', '/c', 'flutter', ...args] : args,
    { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 16 * 1024 * 1024 });
}

function deviceFor(id) {
  const result = command('flutter', ['devices', '--machine'], frontend);
  if (result.error || result.status !== 0) throw new Error(`flutter devices failed: ${result.error?.message ?? result.stderr}`);
  const device = JSON.parse(result.stdout).find((item) => item.id === id &&
    (item.targetPlatform?.startsWith('android') || item.targetPlatform?.startsWith('ios')));
  if (!device) throw new Error(`No connected Android/iOS device ${id}; check flutter devices`);
  return `${device.name} | ${device.targetPlatform} | ${device.sdk}`;
}

function evidence({ flow, device, config, summary, previous, responseData, failures, status, commandLine, exitStatus }) {
  const date = new Date().toISOString().slice(0, 10);
  const dir = path.join(root, 'docs', 'test-runs', date);
  fs.mkdirSync(dir, { recursive: true });
  const revision = command('git', ['rev-parse', 'HEAD']).stdout.trim();
  const changed = command('git', ['status', '--short']).stdout.trim();
  const rows = summary ? metrics.map((key) =>
    `| ${key} | ${summary[key]} | ${previous?.[key] ?? '—'} |`).join('\n') : '| (no frame summary) | — | — |';
  const drawerRows = responseData?.drawer_cases?.map((item) => {
    const frame = responseData[item.frame_report_key];
    return `| ${item.interaction} | ${item.opening} | ${item.open} | ${frame?.frame_count ?? 'missing'} | ${frame?.['90th_percentile_frame_build_time_millis'] ?? 'missing'} | ${frame?.worst_frame_build_time_millis ?? 'missing'} | ${frame?.['90th_percentile_frame_rasterizer_time_millis'] ?? 'missing'} | ${frame?.worst_frame_rasterizer_time_millis ?? 'missing'} |`;
  }).join('\n');
  const drawerEvidenceCases = responseData?.drawer_cases?.map((item) => ({
    ...item,
    frame_summary: responseData[item.frame_report_key] ?? null,
  }));
  const drawerEvidence = flow === 'drawer_open' ?
    `\n## Drawer interactions\n\n` +
    `| Input | Opening | Opened | Frames | Build p90 ms | Build worst ms | Raster p90 ms | Raster worst ms |\n| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |\n${drawerRows || '| no cases | — | — | — | — | — | — | — |'}\n\n` +
    `Native input-to-visible-motion latency: unsupported (not inferred from frame or test-harness time).\n\n` +
    `\`\`\`json\n${JSON.stringify(drawerEvidenceCases ?? null, null, 2)}\n\`\`\`\n` : '';
  const expected = flow === 'drawer_open'
    ? 'Each of six labeled drawer opens has valid build/raster FrameTiming; per-case budgets and same-device case baselines apply. Native input latency is unsupported.'
    : `>=30 frames, build + raster below absolute budgets and within ${config.thresholds.regression_tolerance_pct}% of a measured same-device baseline, zero missed budgets.`;
  const text = `# Performance: ${flow}\n\n` +
    `- Status: **${status}**; exit status: ${exitStatus}\n` +
    `- Tested revision: ${revision}; working-tree changes:\n\n` +
    `\`\`\`text\n${changed || '(clean)'}\n\`\`\`\n\n` +
    `- Environment: ${device}; Flutter profile mode; backend and fixture: see docs/DEVICE_TESTING.md\n` +
    `- Command: \`${commandLine}\`\n` +
    `- Fixture/reset: seeded catalog and posts; stories for story_view; authenticated user with a long real conversation for chat_scroll. Restore the same fixture before comparing.\n` +
    `- Expected: ${expected}\n\n` +
    `| Metric | Actual | Prior baseline |\n| --- | ---: | ---: |\n${rows}\n\n` +
    `- Baseline: \`perf/baselines/${flow}.json\`; recorded at: ${config.recorded_at ?? 'not yet recorded'}\n` +
    `- Result: ${failures.length ? failures.join('; ') : (status === 'NEW BASELINE' ? 'first measurement, regression comparison pending' : 'within budget')}\n` + drawerEvidence;
  fs.writeFileSync(path.join(dir, `perf-${flow}.md`), text);
  console.log(`Evidence: docs/test-runs/${date}/perf-${flow}.md`);
}

function run(flow, id, update) {
  const file = path.join(root, 'perf', 'baselines', `${flow}.json`);
  if (!fs.existsSync(file)) throw new Error(`Unknown flow ${flow}: no perf/baselines/${flow}.json`);
  const config = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [, name] of limits) {
    if (!(config.thresholds?.[name] > 0)) throw new Error(`${flow}: invalid ${name} threshold`);
  }
  if (!Number.isInteger(config.thresholds.missed_frame_budget_count) ||
      config.thresholds.missed_frame_budget_count < 0 ||
      !(config.thresholds.regression_tolerance_pct >= 0)) throw new Error(`${flow}: invalid thresholds`);

  let device;
  try {
    device = deviceFor(id);
  } catch (error) {
    evidence({ flow, device: 'Android/iOS device unavailable', config,
      previous: config.baseline, failures: [error.message], status: 'BLOCKED',
      commandLine: `node scripts/perf-check.js ${flow} --device ${id}${update ? ' --update-baseline' : ''}`,
      exitStatus: 1 });
    throw error;
  }
  if (!update && (flow === 'drawer_open' ? !config.drawer_cases : !config.baseline || !config.recorded_at)) {
    throw new Error(`${flow}: no measured baseline; run --update-baseline first`);
  }
  if (!update && config.device !== device) {
    throw new Error(`${flow}: baseline is for ${config.device}, not ${device}; use matching hardware or --update-baseline`);
  }
  const previous = config.baseline;
  const response = path.join(frontend, 'build', 'integration_response_data.json');
  fs.rmSync(response, { force: true }); // No stale measurement can pass a failed drive.
  const args = ['drive', '--profile', '--no-dds', '-d', id,
    '--driver=test_driver/integration_test.dart', '--target=integration_test/perf_test.dart',
    '--dart-define-from-file=.env', `--dart-define=PERF_FLOW=${flow}`];
  const commandLine = `node scripts/perf-check.js ${flow} --device ${id}${update ? ' --update-baseline' : ''}`;
  console.log(`flutter ${args.join(' ')} (${device})`);
  const result = command('flutter', args, frontend);
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error || result.status !== 0) {
    let responseData;
    try { responseData = JSON.parse(fs.readFileSync(response, 'utf8')); } catch (_) {}
    evidence({ flow, device, config, previous, responseData,
      failures: ['flutter drive failed (see console output)'],
      status: 'BLOCKED', commandLine, exitStatus: result.status ?? 1 });
    throw new Error(`flutter drive failed: ${result.error?.message ?? `exit ${result.status}`}`);
  }

  let responseData;
  try {
    responseData = JSON.parse(fs.readFileSync(response, 'utf8'));
  } catch (_) { // A successful drive with no response is still a failed measurement.
    responseData = null;
  }
  const summary = responseData?.performance;
  const fixture = result.stdout?.match(/Perf fixture missing: ([^\r\n]+)/)?.[1];
  const failures = flow === 'drawer_open' ? [] : summary ? evaluate(summary, config) :
    [fixture ? `Perf fixture missing: ${fixture}` : 'No frame summary from the instrumented interaction'];
  let drawerCaptureFailures = [];
  if (flow === 'drawer_open') {
    drawerCaptureFailures = validateDrawerCases(responseData?.drawer_cases, responseData);
    failures.push(...drawerCaptureFailures);
    if (!drawerCaptureFailures.length) {
      for (const item of responseData.drawer_cases) {
        failures.push(...evaluate(responseData[item.frame_report_key], config, { minimumFrames: 1 })
          .map((failure) => `${item.interaction} ${item.opening}: ${failure}`));
      }
      failures.push(...compareDrawerCases(responseData.drawer_cases, responseData,
        config.drawer_cases, config));
    }
  }
  if (update && failures.length === 0 &&
      (flow === 'drawer_open' || validateSummary(summary).length === 0)) {
    if (flow === 'drawer_open') {
      config.drawer_cases = responseData.drawer_cases.map((item) => {
        return { ...item, frame_summary: responseData[item.frame_report_key] };
      });
      config.baseline = null;
      config.measurement_status =
        'per-case build/raster baseline; native input latency unsupported';
    } else {
      config.baseline = Object.fromEntries(metrics.map((key) => [key, summary[key]]));
    }
    config.recorded_at = new Date().toISOString();
    config.device = device;
    fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`);
  }
  const status = flow !== 'drawer_open' && !summary || flow === 'drawer_open' && drawerCaptureFailures.length
    ? 'BLOCKED' : failures.length ? 'FAIL' : update ? 'NEW BASELINE' : 'PASS';
  evidence({ flow, device, config, summary, previous, responseData, failures, status, commandLine,
    exitStatus: failures.length ? 1 : 0 });
  if (failures.length) throw new Error(`${flow}: ${failures.join('; ')}`);
  console.log(`${flow}: ${status}`);
}

function main(args) {
  const usage = 'Usage: node scripts/perf-check.js <flow|--all> --device <id> [--update-baseline]';
  if (args.includes('--help')) { console.log(usage); return; }
  const [flow, ...flags] = args;
  const deviceIndex = flags.indexOf('--device');
  const id = flags[deviceIndex + 1];
  const update = flags.includes('--update-baseline');
  const remaining = flags.filter((flag, index) => index !== deviceIndex && index !== deviceIndex + 1 && flag !== '--update-baseline');
  if (!flow || !id || !/^[\w.-]+$/.test(id) || remaining.length || (update && process.env.CI)) {
    throw new Error(usage + (update && process.env.CI ? ' (baseline updates are blocked in CI)' : ''));
  }
  const flows = flow === '--all' ? fs.readdirSync(path.join(root, 'perf', 'baselines'))
    .filter((name) => name.endsWith('.json')).map((name) => name.slice(0, -5)) : [flow];
  const errors = [];
  for (const item of flows) {
    try { run(item, id, update); } catch (error) { errors.push(error.message); }
  }
  if (errors.length) throw new Error(errors.join('\n'));
}

if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (error) { console.error(error.message); process.exitCode = 1; }
}
module.exports = { evaluate, validateDrawerCases, compareDrawerCases };
