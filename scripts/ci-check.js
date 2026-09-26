const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const checks = {
  architecture: [
    /\bBaseHttpRepository\b/,
    /\bBasePrismaRepository\b/,
    /\bsafeCall\b/,
    /(?<![/\\])\bsafe(?:Get|GetList|Page|Post|Put|Patch|Delete|Void|Run)\b(?!\.)/,
    /\b_safeMutation\b/,
  ],
  routes: [
    /(?:context|appRouter)\.(?:go|push|pushReplacement|replace)\(\s*['"]\//,
    /\broute\s*:\s*['"]\//,
  ],
  design: [
    /BorderRadius\.(?:circular|all|only|vertical|horizontal)/,
    /(?:StadiumBorder|CircleBorder|CircleAvatar|ClipOval|BoxShape\.circle)/,
    /blurRadius/,
    /Curves\.(?:elasticOut|easeOutBack|easeInOut)/,
    /accentAmber/,
    /Divider\(/,
  ],
};

const sourceRoots = {
  architecture: ['frontend/lib', 'frontend/libs/freebay_design_system/lib', 'nest-backend/src'],
  routes: ['frontend/lib'],
  design: ['frontend/lib', 'frontend/libs/freebay_design_system/lib'],
};

function filesUnder(relativeRoot) {
  const absoluteRoot = path.join(root, relativeRoot);
  if (!fs.existsSync(absoluteRoot)) return [];

  return fs.readdirSync(absoluteRoot, { withFileTypes: true }).flatMap((entry) => {
    const relativePath = path.join(relativeRoot, entry.name);
    if (entry.isDirectory()) return filesUnder(relativePath);
    return /\.(?:dart|ts)$/.test(entry.name)
      && !entry.name.endsWith('.g.dart')
      && !entry.name.endsWith('.freezed.dart')
      ? [relativePath]
      : [];
  });
}

function findLineViolations(content, patterns, relativePath = 'source') {
  const lines = content.split(/\r?\n/);
  return patterns.flatMap((pattern) => lines.flatMap((line, index) => pattern.test(line)
    ? [`${relativePath}:${index + 1}: ${line.trim()}`]
    : []));
}

function violationsFor(checkName) {
  return sourceRoots[checkName].flatMap((sourceRoot) => filesUnder(sourceRoot)).flatMap((relativePath) => {
    const content = fs.readFileSync(path.join(root, relativePath), 'utf8');
    return [...new Set(findLineViolations(content, checks[checkName], relativePath))];
  });
}

function runChecks(selectedChecks = Object.keys(checks)) {
  const failures = selectedChecks.flatMap((checkName) => violationsFor(checkName));
  if (failures.length > 0) {
    console.error(failures.join('\n'));
    console.error('\nCI architecture/style gate failed.');
    return false;
  }
  return true;
}

if (require.main === module) {
  const argumentsList = process.argv.slice(2);
  const invalidArguments = argumentsList.filter((argument) => (
    !argument.startsWith('--') || !(argument.slice(2) in checks)
  ));
  if (invalidArguments.length > 0) {
    console.error(`Unknown CI check option: ${invalidArguments.join(', ')}`);
    process.exitCode = 1;
  } else {
    const selectedChecks = argumentsList.length === 0
      ? Object.keys(checks)
      : argumentsList.map((argument) => argument.slice(2));
    process.exitCode = runChecks(selectedChecks) ? 0 : 1;
  }
}

module.exports = { checks, findLineViolations, runChecks, violationsFor };
