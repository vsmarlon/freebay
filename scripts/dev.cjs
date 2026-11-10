const { spawn, execFileSync } = require('node:child_process');
const net = require('node:net');
const os = require('node:os');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { configureReverse } = require('./adb-reverse-api.cjs');
const { healthService, waitForReadiness } = require('./readiness.cjs');

const root = path.resolve(__dirname, '..');

function controlAddress() {
  const id = createHash('sha256').update(root.toLowerCase()).digest('hex').slice(0, 16);
  return process.platform === 'win32'
    ? `\\\\.\\pipe\\freebay-dev-${id}`
    : path.join(process.env.TMPDIR || os.tmpdir(), `freebay-dev-${id}.sock`);
}

function startStopServer(controller, address = controlAddress()) {
  const server = net.createServer((socket) => {
    socket.once('data', (data) => {
      if (data.toString() === 'stop') controller.abort();
      socket.end();
    });
  });
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(address, () => resolve({
      address: server.address(),
      close: () => new Promise((done) => server.close(done)),
    }));
  });
}

function requestStop(address = controlAddress()) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(address);
    socket.once('connect', () => socket.end('stop'));
    socket.once('close', () => resolve(true));
    socket.once('error', (error) => {
      if (error.code === 'ENOENT' || error.code === 'ECONNREFUSED') resolve(false);
      else reject(error);
    });
  });
}

function readApiBaseUrl(envFile = path.join(root, 'frontend', '.env')) {
  try {
    const line = fs.readFileSync(envFile, 'utf8').split(/\r?\n/)
      .find((entry) => /^\s*API_BASE_URL\s*=/.test(entry));
    const value = line?.replace(/^\s*API_BASE_URL\s*=\s*/, '').trim().replace(/^(?:"(.*)"|'(.*)')$/, '$1$2');
    return value || 'http://localhost:3000';
  } catch {
    return 'http://localhost:3000';
  }
}

async function probeApi(baseUrl) {
  try {
    const target = new URL(baseUrl);
    target.username = '';
    target.password = '';
    const response = await fetch(new URL('/health', target), { signal: AbortSignal.timeout(700) });
    let body;
    try { body = await response.json(); } catch { body = null; }
    if (response.status !== 200 && response.status !== 503) {
      throw new Error('API target mismatch: /health did not identify a FreeBay backend.');
    }
    if (response.status === 200) healthService(body);
    return response.status === 200;
  } catch (error) {
    if (error.message.startsWith('API identity mismatch:') || error.message.startsWith('API target mismatch:')) throw error;
    return false;
  }
}

function localPortOccupied(baseUrl) {
  const target = new URL(baseUrl);
  const host = target.hostname === '[::1]' ? '::1' : target.hostname;
  const port = Number(target.port || (target.protocol === 'https:' ? 443 : 80));
  return new Promise((resolve) => {
    const socket = net.createConnection({ host, port });
    const finish = (occupied) => { socket.destroy(); resolve(occupied); };
    socket.setTimeout(500, () => finish(false));
    socket.once('connect', () => finish(true));
    socket.once('error', () => finish(false));
  });
}

function startBackend({ node = process.execPath, spawnProcess = spawn } = {}) {
  const nest = path.join(root, 'nest-backend', 'node_modules', '@nestjs', 'cli', 'bin', 'nest.js');
  if (!fs.existsSync(nest)) throw new Error('Backend dependencies are not installed; install the existing nest-backend dependencies first.');
  return spawnProcess(node, [nest, 'start', '--watch'], {
    cwd: path.join(root, 'nest-backend'),
    stdio: 'ignore',
    env: process.env,
    windowsHide: true,
    detached: process.platform !== 'win32',
  });
}

function childExit(child) {
  return new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('exit', (code, signal) => reject(new Error(`Backend process exited before readiness (${code ?? signal ?? 'unknown'}).`)));
  });
}

function raceSignal(promise, signal) {
  if (!signal) return promise;
  if (signal.aborted) return Promise.reject(new Error('Development run interrupted.'));
  return new Promise((resolve, reject) => {
    const onAbort = () => reject(new Error('Development run interrupted.'));
    signal.addEventListener('abort', onAbort, { once: true });
    promise.then(resolve, reject).finally(() => signal.removeEventListener('abort', onAbort));
  });
}

async function stopOwnedChild(child, { killTree = (pid) => {
  if (process.platform === 'win32') {
    try { execFileSync('taskkill', ['/PID', String(pid), '/T', '/F'], { stdio: 'ignore' }); } catch {}
  } else {
    try { process.kill(-pid, 'SIGTERM'); } catch {}
  }
} } = {}) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  await new Promise((resolve) => {
    const timer = setTimeout(() => {
      child.removeListener('exit', onExit);
      resolve();
    }, 3_000);
    const onExit = () => { clearTimeout(timer); resolve(); };
    child.once('exit', onExit);
    killTree(child.pid);
    if (child.exitCode !== null || child.signalCode !== null) onExit();
  });
}

async function runWithBackend({
  baseUrl,
  transport,
  probe = probeApi,
  portOccupied = localPortOccupied,
  start = startBackend,
  ready = waitForReadiness,
  stop = stopOwnedChild,
  signal,
  run,
}) {
  const present = await probe(baseUrl);
  if (!present) {
    const hostname = new URL(baseUrl).hostname.replace(/^\[|\]$/g, '');
    if (transport !== 'usb' || !['localhost', '127.0.0.1', '::1'].includes(hostname)) {
      throw new Error('Configured API is unavailable; start its backend or select the intended API in frontend/.env.');
    }
    if (await portOccupied(baseUrl)) {
      await raceSignal(ready({ baseUrl, signal }), signal);
      return run(null);
    }
    const owned = start();
    try {
      await Promise.race([
        raceSignal(ready({ baseUrl, signal }), signal),
        childExit(owned),
      ]);
      return await run(owned);
    } finally {
      await stop(owned);
    }
  }
  await raceSignal(ready({ baseUrl, signal }), signal);
  return run(null);
}

function parseArgs(args) {
  const options = { mode: 'profile', transport: 'usb', device: process.env.FREEBAY_ADB_DEVICE, setupOnly: false };
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (['--mode', '--transport', '--device'].includes(arg)) {
      const value = args[++index];
      if (!value || value.startsWith('--')) throw new Error(`${arg} requires a value.`);
      if (arg === '--mode') options.mode = value;
      else if (arg === '--transport') options.transport = value;
      else options.device = value;
    }
    else if (arg === '--setup-only' || arg === '--watch') options.setupOnly = true;
    else throw new Error(`Unknown dev option: ${arg}`);
  }
  if (!['profile', 'debug'].includes(options.mode)) throw new Error('--mode must be profile or debug.');
  if (!['usb', 'lan'].includes(options.transport)) throw new Error('--transport must be usb or lan.');
  return options;
}

function waitForTarget(command, args, options, signal) {
  const windowsBatch = process.platform === 'win32' && /\.(?:bat|cmd)$/i.test(command);
  const target = windowsBatch
    ? spawn('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', '$a = ConvertFrom-Json $env:FREEBAY_FLUTTER_ARGS; & $env:FREEBAY_FLUTTER_EXE @a; if ($null -eq $LASTEXITCODE) { exit 1 }; exit $LASTEXITCODE'], {
      ...options,
      env: { ...process.env, ...options.env, FREEBAY_FLUTTER_EXE: command, FREEBAY_FLUTTER_ARGS: JSON.stringify(args) },
      stdio: 'inherit',
    })
    : spawn(command, args, { ...options, stdio: 'inherit' });
  return new Promise((resolve, reject) => {
    const onAbort = () => reject(new Error('Development run interrupted.'));
    if (signal?.aborted) onAbort();
    else signal?.addEventListener('abort', onAbort, { once: true });
    target.once('error', reject);
    target.once('exit', (code, childSignal) => {
      signal?.removeEventListener('abort', onAbort);
      if (code === 0) resolve();
      else reject(new Error(`Flutter exited with ${code ?? childSignal ?? 'unknown status'}.`));
    });
  }).finally(() => {
    if (target.exitCode === null && target.signalCode === null) {
      if (process.platform === 'win32') {
        try { execFileSync('taskkill', ['/PID', String(target.pid), '/T', '/F'], { stdio: 'ignore' }); } catch {}
      } else {
        try { target.kill('SIGTERM'); } catch {}
      }
    }
  });
}

function resolveFlutter(command = process.env.FLUTTER || 'flutter') {
  if (typeof command !== 'string' || !command.trim() || /[&|<>^%!"\r\n]/.test(command)) {
    throw new Error('FLUTTER must name an executable, not a command string.');
  }
  const hasPath = path.isAbsolute(command) || command.includes('/') || command.includes('\\');
  let executable = command;
  if (hasPath) {
    executable = path.resolve(command);
    if (!fs.existsSync(executable) || !fs.statSync(executable).isFile()) throw new Error('FLUTTER executable does not exist.');
  } else if (process.platform === 'win32') {
    try {
      executable = execFileSync('where.exe', [command], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).split(/\r?\n/)[0];
    } catch { throw new Error('FLUTTER executable was not found on PATH.'); }
  }
  return executable;
}

async function runDev(options, {
  signal,
  reverse = configureReverse,
  runTarget = waitForTarget,
  withBackend = runWithBackend,
  readApi = readApiBaseUrl,
} = {}) {
  if (signal?.aborted) throw new Error('Development run interrupted.');
  console.log('[FreeBay] Setting up development target.');
  let device;
  if (options.transport === 'usb') device = reverse({ selected: options.device });
  const fromFile = readApi();
  const baseUrl = options.transport === 'usb' ? 'http://127.0.0.1:3000' : fromFile;
  return withBackend({
    baseUrl,
    transport: options.transport,
    signal,
    run: async () => {
      const label = options.transport === 'usb' ? `USB ${device}` : 'LAN API from frontend/.env';
      console.log(`[FreeBay] ${options.mode} target selected (${label}); API, database, and Redis ready.`);
      if (options.setupOnly) {
        if (!signal) throw new Error('--setup-only requires a signal-controlled task process.');
        await new Promise((resolve) => signal.addEventListener('abort', resolve, { once: true }));
      } else {
        const args = [
          'run', options.mode === 'profile' ? '--profile' : '--debug',
          '--dart-define-from-file=.env',
        ];
        if (options.transport === 'usb') args.push('--dart-define=API_BASE_URL=http://localhost:3000');
        if (device) args.push('-d', device);
        await runTarget(resolveFlutter(), args, { cwd: path.join(root, 'frontend') }, signal);
      }
    },
  });
}

async function main(args = process.argv.slice(2)) {
  if (args.length === 1 && args[0] === '--stop-task') {
    await requestStop();
    return;
  }
  const options = parseArgs(args);
  const controller = new AbortController();
  const abort = () => controller.abort();
  process.once('SIGINT', abort);
  process.once('SIGTERM', abort);
  let stopServer;
  try {
    if (options.setupOnly) stopServer = await startStopServer(controller);
    await runDev(options, { signal: controller.signal });
  } finally {
    if (stopServer) await stopServer.close();
    process.removeListener('SIGINT', abort);
    process.removeListener('SIGTERM', abort);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[FreeBay] ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = { controlAddress, parseArgs, probeApi, readApiBaseUrl, requestStop, resolveFlutter, runDev, runWithBackend, startBackend, startStopServer, stopOwnedChild, waitForTarget };
