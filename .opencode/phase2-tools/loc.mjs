#!/usr/bin/env node
// Counts handwritten production source in the two supported FreeBay scopes.
// "code" is nonblank lines (including comments), not parsed executable statements.
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const SCOPES = new Set(['nest-backend/src', 'web/app']);

export function countText(text) {
  if (!text) return { physical: 0, code: 0 };
  const lines = text.split(/\r\n|\n|\r/);
  if (/(?:\r\n|\n|\r)$/.test(text)) lines.pop();
  return { physical: lines.length, code: lines.filter((line) => line.trim().length > 0).length };
}

export function isCounted(relativePath, scope) {
  const name = relativePath.replaceAll('\\', '/');
  if (scope === 'web/app') return /\.tsx?$/.test(name) && !/\.(?:test|spec)\.tsx?$/.test(name);
  if (scope === 'nest-backend/src') {
    return /\.ts$/.test(name)
      && !/\.(?:spec|integration-spec|smoke-spec|e2e-spec)\.ts$/.test(name)
      && !name.split('/').includes('test');
  }
  throw new Error(`Unsupported scope: ${scope}`);
}

function options(argv) {
  const args = { scope: 'nest-backend/src' };
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag === '--json') continue; // Output is JSON by default (legacy CLI compatibility).
    if (!['--scope', '--base', '--out'].includes(flag)) throw new Error(`Unknown option: ${flag}`);
    const value = argv[++i];
    if (!value || value.startsWith('--')) throw new Error(`${flag} requires a value`);
    args[flag.slice(2)] = value;
  }
  if (!SCOPES.has(args.scope)) throw new Error(`Unsupported scope: ${args.scope}`);
  return args;
}

function git(args, input = '') {
  return new Promise((resolve, reject) => {
    const child = spawn('git', args, { cwd: ROOT, windowsHide: true, stdio: [input ? 'pipe' : 'ignore', 'pipe', 'pipe'] });
    const chunks = [];
    let errorOutput = '';
    child.stdout.on('data', (chunk) => chunks.push(chunk));
    child.stderr.on('data', (chunk) => { errorOutput += chunk.toString('utf8'); });
    child.on('error', reject);
    child.on('close', (code) => code === 0
      ? resolve(Buffer.concat(chunks))
      : reject(new Error(`git ${args[0]} failed (${code}): ${errorOutput.trim()}`)));
    if (input) child.stdin.on('error', reject).end(input);
  });
}

function summarize(counts) {
  const total = { files: 0, physical: 0, code: 0 };
  const byArea = {};
  for (const [rel, value] of Object.entries(counts)) {
    const parts = rel.split('/');
    const area = parts[0] === 'modules' && parts.length > 1 ? `modules/${parts[1]}` : parts.length > 1 ? parts[0] : '(root)';
    const group = (byArea[area] ??= { files: 0, physical: 0, code: 0 });
    for (const target of [total, group]) {
      target.files++;
      target.physical += value.physical;
      target.code += value.code;
    }
  }
  return { ...total, byArea };
}

async function countWorkingTree(scope) {
  const counts = {};
  const sourceRoot = path.join(ROOT, ...scope.split('/'));
  async function visit(directory, relative = '') {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const nextPath = path.join(directory, entry.name);
      const nextRelative = relative ? `${relative}/${entry.name}` : entry.name;
      if (entry.isDirectory()) await visit(nextPath, nextRelative);
      else if (entry.isFile() && isCounted(nextRelative, scope)) {
        counts[nextRelative] = countText(await readFile(nextPath, 'utf8'));
      }
    }
  }
  await visit(sourceRoot);
  return counts;
}

async function countAtRevision(revision, scope) {
  const tree = (await git(['ls-tree', '-r', '-z', revision, '--', scope])).toString('utf8');
  const entries = tree.split('\0').filter(Boolean).map((line) => {
    const tab = line.indexOf('\t');
    if (tab < 0) throw new Error('Unexpected git ls-tree entry');
    const [mode, type, sha] = line.slice(0, tab).split(' ');
    const filename = line.slice(tab + 1);
    return { mode, type, sha, filename, rel: filename.slice(scope.length + 1) };
  }).filter(({ type, filename, rel }) => type === 'blob' && filename.startsWith(`${scope}/`) && isCounted(rel, scope));
  if (!entries.length) return {};

  // One batch fetch for every blob. Parse byte lengths, never newline-delimit blob bodies.
  const output = await git(['cat-file', '--batch'], `${entries.map(({ sha }) => sha).join('\n')}\n`);
  let offset = 0;
  const counts = {};
  for (const entry of entries) {
    const newline = output.indexOf(10, offset);
    if (newline === -1) throw new Error('Incomplete git cat-file header');
    const header = output.subarray(offset, newline).toString('ascii');
    const match = /^[a-f0-9]{40,64} blob (\d+)$/.exec(header);
    if (!match) throw new Error(`Unexpected git cat-file header: ${header}`);
    const end = newline + 1 + Number(match[1]);
    if (end >= output.length || output[end] !== 10) throw new Error('Truncated git cat-file blob');
    counts[entry.rel] = countText(output.subarray(newline + 1, end).toString('utf8'));
    offset = end + 1;
  }
  return counts;
}

async function main() {
  const args = options(process.argv.slice(2));
  const currentCounts = await countWorkingTree(args.scope);
  const current = summarize(currentCounts);
  const result = {
    scope: args.scope,
    exclusions: args.scope === 'web/app'
      ? 'test/spec-suffixed *.ts[x]'
      : 'spec/integration-spec/smoke-spec/e2e-spec-suffixed *.ts and src/test/',
    current,
  };
  if (args.base) {
    const baseCounts = await countAtRevision(args.base, args.scope);
    const base = summarize(baseCounts);
    const byArea = {};
    for (const area of new Set([...Object.keys(base.byArea), ...Object.keys(current.byArea)])) {
      const before = base.byArea[area] ?? { files: 0, physical: 0, code: 0 };
      const after = current.byArea[area] ?? { files: 0, physical: 0, code: 0 };
      byArea[area] = {
        files: after.files - before.files,
        physical: after.physical - before.physical,
        code: after.code - before.code,
      };
    }
    const changedFiles = [];
    for (const name of new Set([...Object.keys(baseCounts), ...Object.keys(currentCounts)])) {
      const before = baseCounts[name];
      const after = currentCounts[name];
      if (before?.physical === after?.physical && before?.code === after?.code) continue;
      changedFiles.push({
        path: name,
        status: before === undefined ? 'added' : after === undefined ? 'removed' : 'modified',
        physical: (after?.physical ?? 0) - (before?.physical ?? 0),
        code: (after?.code ?? 0) - (before?.code ?? 0),
      });
    }
    result.base = { sha: args.base, ...base };
    result.delta = {
      files: current.files - base.files,
      physical: current.physical - base.physical,
      code: current.code - base.code,
      byArea,
      changedFiles: changedFiles.sort((a, b) => a.path.localeCompare(b.path)),
    };
  }
  const json = `${JSON.stringify(result, null, 2)}\n`;
  if (args.out) await writeFile(args.out, json, 'utf8');
  else process.stdout.write(json);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
