#!/usr/bin/env node
// Phase 2 LOC baseline/delta tool.
// Requested by the mission as `loc.py`; implemented as Node because no Python
// runtime exists on this machine. Same CLI contract: --base <SHA> --json.
// Counts handwritten TypeScript under nest-backend/src; no tests, no generated.
import { readdir, readFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';

function parseArgs(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i++) {
    const key = argv[i].replace(/^--/, '');
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out[key] = true;
    else {
      out[key] = next;
      i += 1;
    }
  }
  return out;
}

const args = parseArgs(process.argv);
const ROOT = new URL('../../', import.meta.url).pathname
  .replace(/^\/([A-Za-z]:)/, '$1')
  .replace(/\//g, '\\');
const SCOPE = args.scope ?? 'nest-backend/src';
const WEB_RE = /\.tsx?$/;
const WEB_TEST_RE = /\.test\.tsx?$/;
const TS_RE = /\.ts$/;
const TEST_RE = /\.(spec|integration-spec|smoke-spec|e2e-spec)\.ts$/;
const isWebScope = SCOPE.startsWith('web/');

function isCounted(relPath) {
  if (isWebScope) return WEB_RE.test(relPath) && !WEB_TEST_RE.test(relPath);
  return TS_RE.test(relPath) && !TEST_RE.test(relPath) && !relPath.includes('\\test\\');
}

function count(text) {
  const lines = text.split(/\r\n|\n|\r/);
  return { physical: lines.length, code: lines.filter((l) => l.trim().length > 0).length };
}

function areaOf(relPath) {
  const parts = relPath.split('\\');
  if (parts[0] === 'modules' && parts.length > 1) return `modules/${parts[1]}`;
  return parts.length > 1 ? parts[0] : '(root)';
}

async function walk(dir) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = `${dir}\\${entry.name}`;
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else out.push(full);
  }
  return out;
}

async function countWorkingTree() {
  const files = (await walk(`${ROOT}${SCOPE}`)).map((f) => f.slice(ROOT.length + SCOPE.length + 1));
  const counts = {};
  const byArea = {};
  for (const rel of files.filter(isCounted)) {
    const text = await readFile(`${ROOT}${SCOPE}\\${rel}`, 'utf8');
    const c = count(text);
    counts[rel] = c;
    const a = areaOf(rel);
    byArea[a] ??= { files: 0, physical: 0, code: 0 };
    byArea[a].files += 1;
    byArea[a].physical += c.physical;
    byArea[a].code += c.code;
  }
  return { counts, byArea };
}

function git(args) {
  return new Promise((resolve, reject) => {
    const p = spawn('git', args, { cwd: ROOT, windowsHide: true });
    let out = Buffer.alloc(0);
    p.stdout.on('data', (d) => (out = Buffer.concat([out, d])));
    p.stderr.on('data', (d) => process.stderr.write(d));
    p.on('error', reject);
    p.on('close', (code) => (code === 0 ? resolve(out) : reject(new Error(`git ${args.join(' ')} exited ${code}`))));
  });
}

// One `git cat-file --batch` process for every file at the base revision.
async function countAtRevision(sha) {
  const listRaw = await git(['ls-tree', '-r', '--name-only', '-z', sha, '--', SCOPE]);
  const paths = listRaw.toString('utf8').split('\0').filter((p) => p.length > 0 && isCounted(p.replaceAll('/', '\\')));
  const child = spawn('git', ['cat-file', '--batch'], { cwd: ROOT, windowsHide: true });
  const counts = {};
  const byArea = {};
  let buf = Buffer.alloc(0);
  let pending = null; // { rel, size, got, chunks }
  const done = new Promise((resolve, reject) => {
    child.stdout.on('data', (chunk) => {
      buf = Buffer.concat([buf, chunk]);
      for (;;) {
        if (!pending) {
          const nl = buf.indexOf(0x0a);
          if (nl < 0) break;
          const header = buf.subarray(0, nl).toString('utf8');
          buf = buf.subarray(nl + 1);
          const parts = header.split(' ');
          if (parts.length < 3) {
            // A "<request> missing" response carries no content but does consume
            // a queue entry; an empty line is just the blob-content separator.
            if (header.length > 0) queue.shift();
            continue;
          }
          const [, , sizeRaw] = parts;
          const next = queue.shift();
          if (next === undefined) break;
          pending = { rel: next.rel, size: Number(sizeRaw), got: 0, chunks: [] };
        }
        if (buf.length === 0) break;
        const need = pending.size - pending.got;
        const take = buf.subarray(0, need);
        pending.chunks.push(take);
        pending.got += take.length;
        buf = buf.subarray(take.length);
        if (pending.got === pending.size) {
          const text = Buffer.concat(pending.chunks).toString('utf8');
          const c = count(text);
          counts[pending.rel] = c;
          const a = areaOf(pending.rel);
          byArea[a] ??= { files: 0, physical: 0, code: 0 };
          byArea[a].files += 1;
          byArea[a].physical += c.physical;
          byArea[a].code += c.code;
          pending = null;
          if (queue.length === 0 && closedStdin) child.stdin.end();
        }
      }
    });
    child.on('error', reject);
    child.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`cat-file exited ${code}`))));
  });
  const queue = paths.map((p) => ({ request: `${sha}:${p}`, rel: p.slice(SCOPE.length + 1).replaceAll('/', '\\') }));
  for (const { request } of queue) child.stdin.write(`${request}\n`);
  closedStdin = true;
  if (queue.length === 0) child.stdin.end();
  await done;
  return { counts, byArea };
}

let closedStdin = false;

function aggregate(counts) {
  let files = 0;
  let physical = 0;
  let code = 0;
  for (const c of Object.values(counts)) {
    files += 1;
    physical += c.physical;
    code += c.code;
  }
  return { files, physical, code };
}

const current = await countWorkingTree();
const result = {
  scope: SCOPE,
  exclusions: isWebScope
    ? 'test-suffixed *.ts[x] (*.test.ts, *.test.tsx)'
    : 'test-suffixed *.ts (*.spec.ts, *.integration-spec.ts, *.smoke-spec.ts, *.e2e-spec.ts), src\\test\\',
  current: { ...aggregate(current.counts), byArea: current.byArea },
};
if (args.base) {
  const base = await countAtRevision(args.base);
  const curAgg = aggregate(current.counts);
  const baseAgg = aggregate(base.counts);
  const areas = new Set([...Object.keys(base.byArea), ...Object.keys(current.byArea)]);
  const byAreaDelta = {};
  for (const a of areas) {
    const b = base.byArea[a] ?? { files: 0, physical: 0, code: 0 };
    const c = current.byArea[a] ?? { files: 0, physical: 0, code: 0 };
    byAreaDelta[a] = { files: c.files - b.files, physical: c.physical - b.physical, code: c.code - b.code };
  }
  const changed = [];
  for (const p of new Set([...Object.keys(base.counts), ...Object.keys(current.counts)])) {
    const b = base.counts[p];
    const c = current.counts[p];
    if (b === undefined) changed.push({ path: p, status: 'added', physical: c.physical, code: c.code });
    else if (c === undefined) changed.push({ path: p, status: 'removed', physical: -b.physical, code: -b.code });
    else if (b.physical !== c.physical || b.code !== c.code)
      changed.push({ path: p, status: 'modified', physical: c.physical - b.physical, code: c.code - b.code });
  }
  result.base = { sha: args.base, ...baseAgg, byArea: base.byArea };
  result.delta = {
    files: curAgg.files - baseAgg.files,
    physical: curAgg.physical - baseAgg.physical,
    code: curAgg.code - baseAgg.code,
    byArea: byAreaDelta,
    changedFiles: changed.sort((a, b) => a.path.localeCompare(b.path)),
  };
}
const json = `${JSON.stringify(result, null, 2)}\n`;
if (args.out) await (await import('node:fs/promises')).writeFile(args.out, json, 'utf8');
else process.stdout.write(json);
