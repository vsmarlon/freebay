#!/usr/bin/env node
'use strict';

const { createHash } = require('node:crypto');
const { readFileSync, readdirSync, statSync, writeFileSync } = require('node:fs');
const path = require('node:path');

function digestDirectory(root) {
  const files = [];
  function visit(directory) {
    for (const entry of readdirSync(directory).sort()) {
      const absolute = path.join(directory, entry);
      const stat = statSync(absolute);
      if (stat.isDirectory()) visit(absolute);
      else if (stat.isFile()) files.push(path.relative(root, absolute).replaceAll(path.sep, '/'));
      else throw new Error('Artifact contains a non-regular file');
    }
  }
  visit(root);
  if (files.length === 0) throw new Error('Artifact is empty');
  const hash = createHash('sha256');
  for (const file of files) {
    hash.update(file);
    hash.update('\0');
    hash.update(createHash('sha256').update(readFileSync(path.join(root, file))).digest());
    hash.update('\0');
  }
  return { fileCount: files.length, sha256: hash.digest('hex') };
}

function main([action, artifactPath, manifestPath, revision, configuration, verificationPath]) {
  if (!['create', 'verify'].includes(action) || !artifactPath || !manifestPath || !revision || !configuration) {
    throw new Error('Usage: build-manifest.cjs <create|verify> <artifact-dir> <manifest-file> <revision> <configuration> [verification-json]');
  }
  const artifact = digestDirectory(path.resolve(artifactPath));
  const verification = verificationPath ? JSON.parse(readFileSync(path.resolve(verificationPath), 'utf8')) : undefined;
  const expected = { revision, configuration, ...artifact, ...(verification ? { verification } : {}) };
  if (action === 'create') {
    writeFileSync(path.resolve(manifestPath), `${JSON.stringify({ ...expected, node: process.version }, null, 2)}\n`);
  } else {
    const actual = JSON.parse(readFileSync(path.resolve(manifestPath), 'utf8'));
    if (actual.revision !== revision || actual.configuration !== configuration ||
      actual.fileCount !== artifact.fileCount || actual.sha256 !== artifact.sha256) {
      throw new Error('Build artifact manifest mismatch');
    }
    const verification = actual.verification;
    // Intentional quarantines are recorded in skipped; only failures block.
    if (!verification || verification.success !== true || verification.tests < 1 ||
      verification.failed !== 0) {
      throw new Error('Build manifest does not contain a successful non-empty test result');
    }
  }
  process.stdout.write(`${action}: ${artifact.fileCount} files sha256=${artifact.sha256}\n`);
}

if (require.main === module) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : 'Build manifest failed'}\n`);
    process.exitCode = 1;
  }
}

module.exports = { digestDirectory };
