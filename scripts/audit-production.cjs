const { spawnSync } = require('node:child_process');
const path = require('node:path');

const target = process.argv[2];
if (!target) {
  console.error('Usage: node scripts/audit-production.cjs <package-directory>');
  process.exit(2);
}

const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const result = spawnSync(npm, ['audit', '--omit=dev', '--json'], {
  cwd: path.resolve(target),
  encoding: 'utf8',
  shell: process.platform === 'win32',
});

let audit;
try {
  audit = JSON.parse(result.stdout || '{}');
} catch {
  console.error('Could not parse npm audit output.');
  process.exit(2);
}

const counts = audit.metadata?.vulnerabilities;
if (!counts) {
  console.error('npm audit returned no vulnerability metadata.');
  process.exit(2);
}

if (counts.critical > 0) {
  console.error(
    `Production dependency audit failed: ${counts.critical} critical, ${counts.high} high.`,
  );
  process.exit(1);
}

console.log(`Production dependency audit: 0 critical, ${counts.high} high (accepted baseline).`);
