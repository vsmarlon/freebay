const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');
const test = require('node:test');
const { configureReverse, selectDevice } = require('./adb-reverse-api.cjs');
const { parseArgs, readApiBaseUrl, requestStop, resolveFlutter, runDev, runWithBackend, startStopServer, stopOwnedChild, waitForTarget } = require('./dev.cjs');

const single = 'List of devices attached\nA30-serial\tdevice\n';
const multiple = `${single}emulator-5554\tdevice\n`;

test('USB selection rejects no adb device and requires a selector for multiple devices', () => {
  assert.throws(() => selectDevice('List of devices attached\n'), /No authorized adb device/);
  assert.throws(() => selectDevice(multiple), /Multiple adb devices/);
  assert.equal(selectDevice(multiple, 'emulator-5554'), 'emulator-5554');
  assert.throws(() => selectDevice(single, 'not-connected'), /unavailable or unauthorized/);
  assert.throws(() => selectDevice(single, 'A30 & whoami'), /invalid characters/);
});

test('FLUTTER rejects command strings before a shell can execute them', async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'freebay-shell-injection-'));
  const marker = path.join(directory, 'executed');
  const previous = process.env.FLUTTER;
  try {
    process.env.FLUTTER = `flutter & ${process.execPath} -e "require('fs').writeFileSync('${marker}', 'bad')"`;
    await assert.rejects(runDev(parseArgs(['--transport', 'lan']), {
      withBackend: async ({ run }) => run(null),
      readApi: () => 'https://lan.example.test',
    }), /FLUTTER must name an executable/);
    assert.equal(fs.existsSync(marker), false);
  } finally {
    if (previous === undefined) delete process.env.FLUTTER;
    else process.env.FLUTTER = previous;
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test('Windows batch launch accepts an executable path with spaces without shell mode', { skip: process.platform !== 'win32' }, async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'freebay safe launcher '));
  const executable = path.join(directory, 'flutter fixture.cmd');
  fs.writeFileSync(executable, '@echo off\r\nexit /b 0\r\n');
  try {
    assert.equal(resolveFlutter(executable), executable);
    await waitForTarget(executable, ['--version'], { cwd: directory });
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test('reverse uses only the selected device and fails if adb reverse fails', () => {
  const calls = [];
  const selected = configureReverse({ selected: 'A30-serial', execFile: (_cmd, args) => {
    calls.push(args);
    return args[0] === 'devices' ? single : '';
  } });
  assert.equal(selected, 'A30-serial');
  assert.deepEqual(calls[1], ['-s', 'A30-serial', 'reverse', 'tcp:3000', 'tcp:3000']);
  assert.throws(() => configureReverse({ execFile: () => { throw new Error('missing adb'); } }), /adb is unavailable/);
  assert.throws(() => configureReverse({ execFile: (_cmd, args) => {
    if (args[0] === 'devices') return single;
    throw new Error('reverse denied');
  } }), /adb reverse failed/);
});

test('development options default to profile USB and reject unknown targets', () => {
  assert.deepEqual(parseArgs([]), { mode: 'profile', transport: 'usb', device: undefined, setupOnly: false });
  assert.deepEqual(parseArgs(['--mode', 'debug', '--transport', 'lan']), {
    mode: 'debug', transport: 'lan', device: undefined, setupOnly: false,
  });
  assert.throws(() => parseArgs(['--mode', 'release']), /profile or debug/);
  assert.throws(() => parseArgs(['--device']), /requires a value/);
});

test('LAN reads API_BASE_URL without changing the developer env file', () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'freebay-env-'));
  const envFile = path.join(directory, '.env');
  try {
    fs.writeFileSync(envFile, 'API_BASE_URL="https://lan.example.test/api"\nKEEP_ME=existing\n');
    assert.equal(readApiBaseUrl(envFile), 'https://lan.example.test/api');
    assert.equal(fs.readFileSync(envFile, 'utf8'), 'API_BASE_URL="https://lan.example.test/api"\nKEEP_ME=existing\n');
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test('USB run passes the selected serial and localhost define after the env file', async () => {
  let command;
  await runDev(parseArgs(['--mode', 'profile', '--device', 'A30-serial']), {
    reverse: ({ selected }) => selected,
    readApi: () => 'https://lan.example.test',
    withBackend: async ({ baseUrl, run }) => {
      assert.equal(baseUrl, 'http://127.0.0.1:3000');
      return run(null);
    },
    runTarget: async (executable, args, options) => { command = { executable, args, options }; },
  });
  assert.deepEqual(command.args, [
    'run', '--profile', '--dart-define-from-file=.env',
    '--dart-define=API_BASE_URL=http://localhost:3000', '-d', 'A30-serial',
  ]);
  assert.equal(command.options.cwd.endsWith(path.join('frontend')), true);
});

test('LAN run preserves the configured API and never adds the USB override', async () => {
  let command;
  let reverseCalls = 0;
  await runDev(parseArgs(['--mode', 'debug', '--transport', 'lan']), {
    reverse: () => { reverseCalls += 1; throw new Error('LAN must not use adb'); },
    readApi: () => 'https://lan.example.test',
    withBackend: async ({ baseUrl, run }) => {
      assert.equal(baseUrl, 'https://lan.example.test');
      return run(null);
    },
    runTarget: async (executable, args) => { command = { executable, args }; },
  });
  assert.deepEqual(command.args, ['run', '--debug', '--dart-define-from-file=.env']);
  assert.equal(reverseCalls, 0);
});

test('an already-ready backend is reused and never terminated', async () => {
  let starts = 0;
  let stops = 0;
  const result = await runWithBackend({
    baseUrl: 'http://127.0.0.1:3000', transport: 'usb',
    probe: async () => true,
    start: () => { starts += 1; },
    ready: async () => ({ checks: { database: 'healthy', redis: 'healthy' } }),
    stop: async () => { stops += 1; },
    run: async (owned) => owned,
  });
  assert.equal(result, null);
  assert.equal(starts, 0);
  assert.equal(stops, 0);
});

test('only a backend process started by this run is cleaned up, including readiness failure', async () => {
  const child = new EventEmitter();
  child.exitCode = null;
  child.signalCode = null;
  let starts = 0;
  let stopped = 0;
  const dependencies = {
    baseUrl: 'http://127.0.0.1:3000', transport: 'usb',
    probe: async () => false,
    portOccupied: async () => false,
    start: () => { starts += 1; return child; },
    stop: async (owned) => { assert.equal(owned, child); stopped += 1; },
    run: async () => 'ran',
  };
  assert.equal(await runWithBackend({ ...dependencies, ready: async () => ({}) }), 'ran');
  await assert.rejects(runWithBackend({ ...dependencies, ready: async () => { throw new Error('timeout'); } }), /timeout/);
  assert.equal(starts, 2);
  assert.equal(stopped, 2);
});

test('an occupied but unidentified local port is readiness-checked, never overwritten', async () => {
  let starts = 0;
  await assert.rejects(runWithBackend({
    baseUrl: 'http://127.0.0.1:3000', transport: 'usb',
    probe: async () => false,
    portOccupied: async () => true,
    start: () => { starts += 1; },
    ready: async () => { throw new Error('API identity mismatch'); },
    run: async () => {},
  }), /API identity mismatch/);
  assert.equal(starts, 0);
});

test('a missing LAN target is not replaced by a local backend', async () => {
  let starts = 0;
  await assert.rejects(runWithBackend({
    baseUrl: 'https://api.example', transport: 'lan', probe: async () => false,
    start: () => { starts += 1; }, ready: async () => {}, run: async () => {},
  }), /Configured API is unavailable/);
  assert.equal(starts, 0);
});

test('VS Code post-debug stop signals only the owned setup task over its local control socket', async () => {
  const controller = new AbortController();
  const server = await startStopServer(controller, { host: '127.0.0.1', port: 0 });
  try {
    assert.equal(await requestStop(server.address), true);
    assert.equal(controller.signal.aborted, true);
  } finally {
    await server.close();
  }
});

test('cleanup terminates only the child process fixture it owns', async () => {
  const child = spawn(process.execPath, ['-e', 'process.on("SIGTERM", () => process.exit(0)); setInterval(() => {}, 1000)'], { stdio: 'ignore' });
  try {
    await new Promise((resolve, reject) => {
      child.once('spawn', resolve);
      child.once('error', reject);
    });
    await stopOwnedChild(child, { killTree: (pid) => {
      assert.equal(pid, child.pid);
      child.kill('SIGTERM');
    } });
    assert.ok(child.exitCode !== null || child.signalCode !== null);
  } finally {
    if (child.exitCode === null && child.signalCode === null) child.kill('SIGKILL');
  }
});

test('Windows cleanup kills only the spawned owned process tree', { skip: process.platform !== 'win32' }, async () => {
  const child = spawn('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 30'], { stdio: 'ignore', windowsHide: true });
  await new Promise((resolve, reject) => {
    child.once('spawn', resolve);
    child.once('error', reject);
  });
  await stopOwnedChild(child);
  assert.ok(child.exitCode !== null || child.signalCode !== null);
});
