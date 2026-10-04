const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const designBaselinePath = path.join(__dirname, 'design-baseline.json');
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

const designRatchetRules = {
  D1: /\bisDark\s*\?\s*[^;]*\b(?:color|Color|Colors|AppColors)\b[^:]*:/,
  D3: /(?:#[0-9a-fA-F]{6,8}\b|\bColors\.(?!transparent\b)[A-Za-z_]\w*)/,
  D4: /(?:EdgeInsets\.(?:all|only|symmetric|fromLTRB)\s*\([^)]*|SizedBox\s*\([^)]*)/,
};

const movedDesignBaselinePaths = new Map([
  ['frontend/lib/features/media_editor/presentation/pages/image_editor_page.dart', 'frontend/lib/features/chat/presentation/pages/image_editor_page.dart'],
  ['frontend/lib/features/media_editor/presentation/widgets/draw_palette.dart', 'frontend/lib/features/chat/presentation/widgets/draw_palette.dart'],
  ['frontend/lib/features/media_editor/presentation/widgets/image_editor_toolbar.dart', 'frontend/lib/features/chat/presentation/widgets/image_editor_toolbar.dart'],
  ['frontend/lib/features/media_editor/presentation/widgets/image_editor_views.dart', 'frontend/lib/features/chat/presentation/widgets/image_editor_views.dart'],
  ['frontend/lib/features/stories/presentation/pages/create_story_page.dart', 'frontend/lib/features/social/presentation/pages/create_story_page.dart'],
  ['frontend/lib/features/stories/presentation/pages/my_stories_page.dart', 'frontend/lib/features/social/presentation/pages/my_stories_page.dart'],
  ['frontend/lib/features/stories/presentation/pages/story_viewer_page.dart', 'frontend/lib/features/social/presentation/pages/story_viewer_page.dart'],
  ['frontend/lib/features/stories/presentation/pages/story_viewer_wrapper.dart', 'frontend/lib/features/social/presentation/pages/story_viewer_wrapper.dart'],
  ['frontend/lib/features/stories/presentation/widgets/stories_row.dart', 'frontend/lib/features/social/presentation/widgets/stories_row.dart'],
  ['frontend/lib/features/stories/presentation/widgets/story_canvas.dart', 'frontend/lib/features/social/presentation/widgets/story_canvas.dart'],
  ['frontend/lib/features/stories/presentation/widgets/story_capture_view.dart', 'frontend/lib/features/social/presentation/widgets/story_capture_view.dart'],
  ['frontend/lib/features/stories/presentation/widgets/story_highlights_section.dart', 'frontend/lib/features/social/presentation/widgets/story_highlights_section.dart'],
  ['frontend/lib/features/stories/presentation/widgets/story_page.dart', 'frontend/lib/features/social/presentation/widgets/story_page.dart'],
  ['frontend/lib/features/stories/presentation/widgets/story_preview_view.dart', 'frontend/lib/features/social/presentation/widgets/story_preview_view.dart'],
]);

function designFindings(content, relativePath) {
  const lines = content.split(/\r?\n/);
  const findings = [];
  let textStyleDepth = 0;
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index].replace(/\/\/.*$/, '');
    if (textStyleDepth > 0 || /\bTextStyle\s*\(/.test(line)) {
      if (/\bfontSize\s*:\s*\d+(?:\.\d+)?/.test(line)) {
        findings.push({ file: relativePath, specifier: 'fontSize', rule: 'D2' });
      }
      textStyleDepth += (line.match(/\(/g) || []).length - (line.match(/\)/g) || []).length;
      if (textStyleDepth < 0) textStyleDepth = 0;
    }
    for (const [rule, pattern] of Object.entries(designRatchetRules)) {
      const match = line.match(pattern);
      if (!match) continue;
      const specifier = rule === 'D1' ? 'color ternary'
        : rule === 'D3' ? match[0]
          : match[0].replace(/\s*\(.*/, '');
      if (rule === 'D4') {
        const values = [...match[0].matchAll(/\d+(?:\.\d+)?/g)]
          .map((value) => Number(value[0]));
        if (values.length === 0) continue;
        if (values.every((value) => [4, 8, 16, 24, 32, 48].includes(value))) continue;
      }
      findings.push({ file: relativePath, specifier, rule });
    }
  }
  return findings;
}

function currentDesignFindings() {
  return filesUnder('frontend/lib/features')
    .filter((file) => (
      file.endsWith('.dart')
      && !file.endsWith('.g.dart')
      && !file.endsWith('.freezed.dart')
    ))
    .flatMap((file) => designFindings(
      fs.readFileSync(path.join(root, file), 'utf8'),
      movedDesignBaselinePaths.get(file.replace(/\\/g, '/')) || file.replace(/\\/g, '/'),
    ))
    .sort(compareFinding);
}

function findingKey(finding) {
  return `${finding.file}\0${finding.specifier}\0${finding.rule}`;
}

function compareFinding(a, b) {
  const left = findingKey(a);
  const right = findingKey(b);
  return left < right ? -1 : left > right ? 1 : 0;
}

function checkRatchet(current, baseline) {
  const counts = (findings) => findings.reduce((result, finding) => {
    const key = findingKey(finding);
    result.set(key, (result.get(key) || 0) + 1);
    return result;
  }, new Map());
  const baseCounts = counts(baseline);
  const currentCounts = counts(current);
  const additionsLeft = new Map([...currentCounts].map(([key, count]) => [key, count - (baseCounts.get(key) || 0)]));
  const resolvedLeft = new Map([...baseCounts].map(([key, count]) => [key, count - (currentCounts.get(key) || 0)]));
  const selectExtra = (findings, extra) => {
    const seen = new Map();
    return findings.filter((finding) => {
      const key = findingKey(finding);
      const occurrence = (seen.get(key) || 0) + 1;
      seen.set(key, occurrence);
      return occurrence <= (extra.get(key) || 0);
    });
  };
  return {
    additions: selectExtra(current, additionsLeft),
    resolved: selectExtra(baseline, resolvedLeft),
  };
}

function shrinkBaseline(current, baseline) {
  const { additions, resolved } = checkRatchet(current, baseline);
  if (additions.length > 0) throw new Error('Design baseline updates cannot add findings.');
  const resolvedCounts = resolved.reduce((result, finding) => {
    const key = findingKey(finding);
    result.set(key, (result.get(key) || 0) + 1);
    return result;
  }, new Map());
  return baseline.filter((item) => {
    const key = findingKey(item);
    const remaining = resolvedCounts.get(key) || 0;
    if (remaining === 0) return true;
    resolvedCounts.set(key, remaining - 1);
    return false;
  });
}

function runDesignRatchet({ update = false } = {}) {
  const current = currentDesignFindings();
  if (!fs.existsSync(designBaselinePath)) {
    console.error('Missing scripts/design-baseline.json; refusing to create a baseline during checks.');
    return false;
  }
  const baseline = JSON.parse(fs.readFileSync(designBaselinePath, 'utf8'));
  const { additions, resolved } = checkRatchet(current, baseline);
  if (additions.length > 0) {
    console.error(`Design ratchet additions:\n${JSON.stringify(additions, null, 2)}`);
    return false;
  }
  if (update && resolved.length > 0) {
    fs.writeFileSync(designBaselinePath, `${JSON.stringify(shrinkBaseline(current, baseline), null, 2)}\n`);
  }
  return true;
}

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
  if (argumentsList.some((argument) => argument === '--design-ratchet' || argument === '--update-baseline')) {
    const update = argumentsList.includes('--update-baseline');
    const invalid = argumentsList.filter((argument) => !['--design-ratchet', '--update-baseline'].includes(argument));
    process.exitCode = invalid.length === 0 && runDesignRatchet({ update }) ? 0 : 1;
  } else {
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
      const checksPass = runChecks(selectedChecks);
      const ratchetPass = selectedChecks.includes('design') || argumentsList.length === 0
        ? runDesignRatchet()
        : true;
      process.exitCode = checksPass && ratchetPass ? 0 : 1;
    }
  }
}

module.exports = { checks, findLineViolations, runChecks, violationsFor, checkRatchet, shrinkBaseline, designFindings, movedDesignBaselinePaths };
