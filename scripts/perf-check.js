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

function validateSummary(summary) {
  const failures = [];
  for (const name of metrics) {
    const value = summary?.[name];
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 ||
        (name.endsWith('_count') || name === 'frame_count') && !Number.isInteger(value)) {
      failures.push(`${name} missing or invalid`);
    }
  }
  if (typeof summary?.frame_count === 'number' && summary.frame_count < 30) {
    failures.push('frame_count below 30: interaction was not measured');
  }
  return failures;
}

function evaluate(summary, config) {
  const failures = validateSummary(summary);
  if (failures.length) return failures;

  for (const [metric, threshold] of limits) {
    const max = config.thresholds[threshold];
    if (summary[metric] >= max) failures.push(`${metric} ${summary[metric]}ms >= ${max}ms`);
    const prior = config.baseline?.[metric];
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

function evidence({ flow, device, config, summary, previous, failures, status, commandLine, exitStatus }) {
  const date = new Date().toISOString().slice(0, 10);
  const dir = path.join(root, 'docs', 'test-runs', date);
  fs.mkdirSync(dir, { recursive: true });
  const revision = command('git', ['rev-parse', 'HEAD']).stdout.trim();
  const changed = command('git', ['status', '--short']).stdout.trim();
  const rows = summary ? metrics.map((key) =>
    `| ${key} | ${summary[key]} | ${previous?.[key] ?? '—'} |`).join('\n') : '| (no frame summary) | — | — |';
  const text = `# Performance: ${flow}\n\n` +
    `- Status: **${status}**; exit status: ${exitStatus}\n` +
    `- Tested revision: ${revision}; working-tree changes:\n\n` +
    `\`\`\`text\n${changed || '(clean)'}\n\`\`\`\n\n` +
    `- Environment: ${device}; Flutter profile mode; backend and fixture: see docs/DEVICE_TESTING.md\n` +
    `- Command: \`${commandLine}\`\n` +
    `- Fixture/reset: seeded catalog and posts; stories for story_view; authenticated user with a long real conversation for chat_scroll. Restore the same fixture before comparing.\n` +
    `- Expected: >=30 frames, build + raster below absolute budgets and within ${config.thresholds.regression_tolerance_pct}% of a measured same-device baseline, zero missed budgets.\n\n` +
    `| Metric | Actual | Prior baseline |\n| --- | ---: | ---: |\n${rows}\n\n` +
    `- Baseline: \`perf/baselines/${flow}.json\`; recorded at: ${config.recorded_at ?? 'not yet recorded'}\n` +
    `- Result: ${failures.length ? failures.join('; ') : (status === 'NEW BASELINE' ? 'first measurement, regression comparison pending' : 'within budget')}\n`;
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
  if (!update && (!config.baseline || !config.recorded_at)) {
    throw new Error(`${flow}: no measured baseline; run --update-baseline first`);
  }
  if (!update && config.device !== device) {
    throw new Error(`${flow}: baseline is for ${config.device}, not ${device}; use matching hardware or --update-baseline`);
  }
  if (device.includes(' | android')) {
    const mappings = command('adb', ['-s', id, 'reverse', '--list']);
    if (mappings.error || mappings.status !== 0) {
      throw new Error(`adb reverse inspection failed: ${mappings.error?.message ?? mappings.stderr}`);
    }
    if (!mappings.stdout.split(/\r?\n/).some((line) => line.trim().split(/\s+/)[1] === 'tcp:3000')) {
      const reverse = command('adb', ['-s', id, 'reverse', 'tcp:3000', 'tcp:3000']);
      if (reverse.error || reverse.status !== 0) {
        throw new Error(`adb reverse failed: ${reverse.error?.message ?? reverse.stderr}`);
      }
    }
  }
  const previous = config.baseline;
  const response = path.join(frontend, 'build', 'integration_response_data.json');
  fs.rmSync(response, { force: true }); // No stale measurement can pass a failed drive.
  const args = ['drive', '--profile', '--no-dds', '-d', id,
    '--driver=test_driver/integration_test.dart', '--target=integration_test/perf_test.dart',
    `--dart-define=PERF_FLOW=${flow}`];
  const commandLine = `node scripts/perf-check.js ${flow} --device ${id}${update ? ' --update-baseline' : ''}`;
  console.log(`flutter ${args.join(' ')} (${device})`);
  const result = command('flutter', args, frontend);
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error || result.status !== 0) {
    evidence({ flow, device, config, previous, failures: ['flutter drive failed (see console output)'],
      status: 'BLOCKED', commandLine, exitStatus: result.status ?? 1 });
    throw new Error(`flutter drive failed: ${result.error?.message ?? `exit ${result.status}`}`);
  }

  let summary;
  try {
    summary = JSON.parse(fs.readFileSync(response, 'utf8')).performance;
  } catch (_) { // A successful drive with no response is still a failed measurement.
    summary = null;
  }
  const fixture = result.stdout?.match(/Perf fixture missing: ([^\r\n]+)/)?.[1];
  const failures = summary ? evaluate(summary, config) :
    [fixture ? `Perf fixture missing: ${fixture}` : 'No frame summary from the instrumented interaction'];
  if (update && validateSummary(summary).length === 0) {
    config.baseline = Object.fromEntries(metrics.map((key) => [key, summary[key]]));
    config.recorded_at = new Date().toISOString();
    config.device = device;
    fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`);
    if (failures.length) console.log(`${flow}: baseline measured but absolute budget still fails`);
  }
  const status = !summary ? 'BLOCKED' : failures.length ? 'FAIL' : update ? 'NEW BASELINE' : 'PASS';
  evidence({ flow, device, config, summary, previous, failures, status, commandLine,
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
module.exports = { evaluate };
