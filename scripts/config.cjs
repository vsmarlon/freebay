#!/usr/bin/env node
// FreeBay configuration contract CLI (CFG lane, ADR 0010).
//
//   node scripts/config.cjs validate [--profile development|test|production|all]
//   node scripts/config.cjs doctor   --profile <profile>
//   node scripts/config.cjs generate --profile <profile> --target backend|web|flutter|all [--dry-run]
//
// The committed config.yaml is the default; --file accepts another YAML for
// tests. Output is deterministic. Nothing here prints or persists secrets.

const fs = require('node:fs');
const path = require('node:path');
const { parse } = require('yaml');

const ROOT = path.resolve(__dirname, '..');
const DEFAULT_FILE = path.join(ROOT, 'config.yaml');
const GENERATED_DIR = path.join(ROOT, '.config-generated');

const PROFILES = ['development', 'test', 'production'];
const TARGETS = ['backend', 'web', 'flutter'];

// Deployment-owned keys: non-secret, public-safe, but only the deployment
// environment may supply them for production. No localhost fallback exists.
const PRODUCTION_ENV_REQUIREMENTS = {
  backend: {
    allowedOrigins: 'ALLOWED_ORIGINS',
    appUrl: 'APP_URL',
  },
  web: {
    backendOrigin: 'BACKEND_URL',
    googleWebClientId: 'VITE_GOOGLE_WEB_CLIENT_ID',
  },
  flutter: {
    apiBaseUrl: 'API_BASE_URL',
  },
};

// Any of these keys appearing in config.yaml is rejected outright.
const SECRET_KEY_PATTERN =
  /(DATABASE_URL|JWT_SECRET|JWT_REFRESH|JWT_BIOMETRIC|CPF_ENCRYPTION_KEY|CPF_HMAC_KEY|STRIPE_SECRET|STRIPE_WEBHOOK_SECRET|FIREBASE_PRIVATE_KEY|FIREBASE_CLIENT_EMAIL|SMTP_PASS|SMTP_USER|TWILIO_AUTH_TOKEN|TWILIO_ACCOUNT_SID|PRIVATE_KEY|PASSWO?RD|SECRET|TOKEN|CREDENTIAL)/i;

// Secret VALUES smuggled under benign keys are rejected too: a public-id slot
// must never carry key material, whatever the key is called.
const SECRET_VALUE_PATTERNS = [
  { re: /^-----BEGIN [A-Z ]*PRIVATE KEY-----/, label: 'private key material' },
  { re: /sk_(?:live|test)_[A-Za-z0-9]{8,}/, label: 'a Stripe secret key' },
  { re: /eyJhbGciOi[A-Za-z0-9_-]{10,}/, label: 'JWT material' },
];

const SCHEMA = {
  backend: {
    port: 'port',
    allowedOrigins: 'urlList',
    appUrl: 'urlOrEmpty',
    email: ['smtp-ethereal', 'mock', 'real'],
    sms: ['console-code', 'mock', 'real'],
    payments: ['stripe-test', 'mock', 'stripe-live'],
    push: ['fcm', 'mock'],
    storage: ['local-disk'],
    swagger: 'boolean',
    debugDiagnostics: 'boolean',
  },
  web: {
    backendOrigin: 'urlOrEmpty',
    network: ['real', 'fixture'],
    googleWebClientId: 'string',
    appleWebClientId: 'string',
  },
  flutter: {
    apiBaseUrl: 'urlOrEmpty',
    notifications: ['fcm', 'mock'],
    debugDiagnostics: 'boolean',
    googlePayTestEnvironment: 'boolean',
  },
};

function fail(message) {
  throw new Error(message);
}

function validUrl(value) {
  try {
    const url = new URL(value);
    return url.hostname.length > 0;
  } catch {
    return false;
  }
}

function checkValue(profile, target, key, spec, value, errors) {
  const where = `profiles.${profile}.${target}.${key}`;
  if (Array.isArray(spec)) {
    if (!spec.includes(value)) errors.push(`${where} must be one of: ${spec.join(', ')} (got "${value}")`);
  } else if (spec === 'port') {
    if (!Number.isInteger(value) || value < 1 || value > 65535) errors.push(`${where} must be an integer between 1 and 65535`);
  } else if (spec === 'boolean') {
    if (typeof value !== 'boolean') errors.push(`${where} must be true or false`);
  } else if (spec === 'string') {
    if (typeof value !== 'string') errors.push(`${where} must be a string`);
  } else if (spec === 'urlOrEmpty') {
    if (value !== '' && (typeof value !== 'string' || !validUrl(value))) errors.push(`${where} must be a valid URL or an empty string`);
  } else if (spec === 'urlList') {
    if (!Array.isArray(value) || !value.every((origin) => typeof origin === 'string' && validUrl(origin))) {
      errors.push(`${where} must be a list of valid URLs`);
    }
  }
}

function walkForSecrets(node, prefix, errors) {
  if (node && typeof node === 'object' && !Array.isArray(node)) {
    for (const [key, value] of Object.entries(node)) {
      if (SECRET_KEY_PATTERN.test(key)) errors.push(`${prefix}${key}: secrets never belong in config.yaml; supply it via the deployment environment`);
      if (typeof value === 'string' && value.length > 8) {
        for (const { re, label } of SECRET_VALUE_PATTERNS) {
          if (re.test(value)) {
            errors.push(`${prefix}${key}: value looks like ${label}; secrets never belong in config.yaml`);
            break;
          }
        }
        try {
          const url = new URL(value);
          if (url.username || url.password) errors.push(`${prefix}${key}: URL carries embedded credentials; never put credentials in config.yaml`);
        } catch { /* not a URL */ }
      }
      walkForSecrets(value, `${prefix}${key}.`, errors);
    }
  }
}

function isLoopbackOrPrivateHost(hostname) {
  const host = hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (host === 'localhost' || host === '::1') return true;
  const parts = host.split('.');
  if (parts.length !== 4 || !parts.every((part) => /^\d{1,3}$/.test(part))) return false;
  const octets = parts.map(Number);
  return octets[0] === 127 ||
    octets[0] === 10 ||
    (octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31) ||
    (octets[0] === 192 && octets[1] === 168);
}

function validateProductionFailClosed(profile, config, env, errors) {
  if (profile !== 'production') return;
  const { backend, web, flutter } = config.profiles.production;
  const expectations = [
    [backend.email, 'email', 'real'],
    [backend.sms, 'sms', 'real'],
    [backend.payments, 'payments', 'stripe-live'],
    [backend.push, 'push', 'fcm'],
    [backend.swagger, 'swagger', false],
    [backend.debugDiagnostics, 'debugDiagnostics', false],
    [web.network, 'network', 'real'],
    [flutter.notifications, 'notifications', 'fcm'],
    [flutter.debugDiagnostics, 'debugDiagnostics', false],
    [flutter.googlePayTestEnvironment, 'googlePayTestEnvironment', false],
  ];
  for (const [actual, key, expected] of expectations) {
    if (actual !== expected) {
      errors.push(`profiles.production: mock or debug escape rejected — ${key} must be ${typeof expected === 'string' ? `"${expected}"` : expected} (got "${actual}")`);
    }
  }
  for (const url of [backend.appUrl, web.backendOrigin, flutter.apiBaseUrl]) {
    if (url !== '' && !url.startsWith('https://')) {
      errors.push('profiles.production: every configured URL must use https');
    }
  }
  for (const url of [backend.appUrl, web.backendOrigin, flutter.apiBaseUrl, ...backend.allowedOrigins]) {
    if (url === '') continue;
    try {
      if (isLoopbackOrPrivateHost(new URL(url).hostname)) {
        errors.push(`profiles.production: "${url}" is a loopback or private address; production endpoints must be public (no localhost fallback exists)`);
      }
    } catch { /* malformed URLs are reported by the structural checks */ }
  }
  if (backend.allowedOrigins.some((origin) => !origin.startsWith('https://'))) {
    errors.push('profiles.production: allowedOrigins must use https');
  }
  // Deployment-owned endpoints have no fallback: they must come from the env.
  for (const target of TARGETS) {
    const required = PRODUCTION_ENV_REQUIREMENTS[target];
    const block = config.profiles.production[target];
    for (const [key, envName] of Object.entries(required)) {
      const empty = key === 'allowedOrigins' ? block[key].length === 0 : block[key] === '';
      if (empty && !env[envName]) {
        errors.push(`profiles.production.${target}.${key} is deployment-owned and empty: provide ${envName} in the deployment environment (no localhost fallback exists)`);
      }
    }
  }
}

function checkNodeEnvAgreement(profile, env, errors) {
  const nodeEnv = env.NODE_ENV;
  if (profile === 'production') {
    if (nodeEnv !== 'production') {
      errors.push(`NODE_ENV must be production for the production profile (got ${nodeEnv ?? 'unset'}); production has no silent fallback`);
    }
    return;
  }
  if (nodeEnv === 'production') {
    errors.push(`NODE_ENV=production conflicts with the selected ${profile} profile; production mode must use the production profile`);
  }
}

function loadAndValidate(file = DEFAULT_FILE, env = process.env, selectedProfile = null) {
  const errors = [];
  let raw;
  try {
    raw = fs.readFileSync(file, 'utf8');
  } catch {
    return { errors: [`cannot read ${path.relative(ROOT, file)}`] };
  }
  let config;
  try {
    config = parse(raw);
  } catch (error) {
    return { errors: [`YAML parse error in ${path.relative(ROOT, file)}: ${error.message}`] };
  }
  if (!config || typeof config !== 'object' || Array.isArray(config)) {
    return { errors: ['config must be a YAML mapping'] };
  }
  walkForSecrets(config, '', errors);

  if (config.schemaVersion !== 1) errors.push(`schemaVersion must be 1 (got "${config.schemaVersion}")`);
  const unknownTop = Object.keys(config).filter((key) => key !== 'schemaVersion' && key !== 'profiles');
  if (unknownTop.length) errors.push(`unknown top-level keys: ${unknownTop.join(', ')}`);

  const profiles = config.profiles;
  if (!profiles || typeof profiles !== 'object' || Array.isArray(profiles)) {
    errors.push('profiles mapping is required');
    return { errors };
  }
  const missing = PROFILES.filter((name) => !(name in profiles));
  if (missing.length) errors.push(`missing profiles: ${missing.join(', ')}`);
  const extra = Object.keys(profiles).filter((name) => !PROFILES.includes(name));
  if (extra.length) errors.push(`unknown profiles (only development, test, production): ${extra.join(', ')}`);

  // Structural checks (schema, enums, unknown keys, secrets, URLs) cover the
  // entire matrix. Env-dependent checks (NODE_ENV agreement, production
  // fail-closed requirements) apply only to the profile being selected — a
  // locally missing deployment value must not condemn unrelated profiles.
  const activeProfiles = selectedProfile ? [selectedProfile] : PROFILES;

  for (const profile of PROFILES) {
    const block = profiles[profile];
    if (!block || typeof block !== 'object') {
      errors.push(`profiles.${profile} mapping is required`);
      continue;
    }
    const unknownTargets = Object.keys(block).filter((name) => !TARGETS.includes(name));
    if (unknownTargets.length) errors.push(`profiles.${profile}: unknown targets ${unknownTargets.join(', ')}`);
    for (const target of TARGETS) {
      const targetBlock = block[target];
      if (!targetBlock || typeof targetBlock !== 'object') {
        errors.push(`profiles.${profile}.${target} mapping is required`);
        continue;
      }
      const schema = SCHEMA[target];
      const unknownKeys = Object.keys(targetBlock).filter((key) => !(key in schema));
      if (unknownKeys.length) errors.push(`profiles.${profile}.${target}: unknown keys ${unknownKeys.join(', ')}`);
      const missingKeys = Object.keys(schema).filter((key) => !(key in targetBlock));
      if (missingKeys.length) errors.push(`profiles.${profile}.${target}: missing keys ${missingKeys.join(', ')}`);
      for (const [key, spec] of Object.entries(schema)) {
        if (key in targetBlock) checkValue(profile, target, key, spec, targetBlock[key], errors);
      }
    }
    if (activeProfiles.includes(profile)) checkNodeEnvAgreement(profile, env, errors);
    if (profile === 'production' && activeProfiles.includes(profile)) validateProductionFailClosed(profile, config, env, errors);
  }

  return { config, errors };
}

function resolvedSnapshot(config, profile) {
  const block = config.profiles[profile];
  const snapshot = { schemaVersion: 1, profile };
  for (const target of TARGETS) snapshot[target] = block[target];
  return snapshot;
}

function generateArtifact(config, profile, target, { env = process.env } = {}) {
  const block = config.profiles[profile][target];
  const artifact = { schemaVersion: 1, profile, target, values: {} };
  const required = profile === 'production' ? PRODUCTION_ENV_REQUIREMENTS[target] : {};
  for (const [key, value] of Object.entries(block)) {
    const envName = required[key];
    if (envName && env[envName]) artifact.values[key] = env[envName];
    else artifact.values[key] = value;
  }
  if (profile === 'production') {
    artifact.deploymentEnv = Object.values(required);
  }
  return artifact;
}

function stableJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function writeArtifact(profile, target, artifact, { dryRun = false } = {}) {
  const file = path.join(GENERATED_DIR, `${profile}.${target}.json`);
  const content = stableJson(artifact);
  if (dryRun) return { file, content, written: false };
  fs.mkdirSync(GENERATED_DIR, { recursive: true });
  const tmp = `${file}.tmp`;
  fs.writeFileSync(tmp, content, 'utf8');
  fs.renameSync(tmp, file);
  return { file, content, written: true };
}

function doctorReport(config, profile, env) {
  const lines = [];
  lines.push(`profile: ${profile}`);
  lines.push(`nodeEnv: ${env.NODE_ENV ?? '(unset — development assumed)'}`);
  const deploymentKeys = [
    'ALLOWED_ORIGINS', 'APP_URL', 'BACKEND_URL', 'VITE_GOOGLE_WEB_CLIENT_ID', 'API_BASE_URL',
    'DATABASE_URL', 'REDIS_URL', 'JWT_SECRET', 'STRIPE_SECRET_KEY', 'FIREBASE_PROJECT_ID',
  ];
  for (const key of deploymentKeys) {
    lines.push(`${key}: ${env[key] ? 'set (value hidden)' : 'not set'}`);
  }
  const snapshot = resolvedSnapshot(config, profile);
  lines.push(`resolved (redacted): ${JSON.stringify(snapshot)}`);
  return lines.join('\n');
}

function parseArgs(argv) {
  const options = { command: argv[0], profile: argv.includes('--all') ? 'all' : 'development', target: null, dryRun: false, file: DEFAULT_FILE };
  const values = { '--profile': 'profile', '--target': 'target', '--file': 'file' };
  for (let index = 1; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--all') continue;
    if (arg === '--dry-run') { options.dryRun = true; continue; }
    const name = values[arg];
    if (!name) fail(`unknown option: ${arg}`);
    const value = argv[++index];
    if (!value) fail(`${arg} requires a value`);
    options[name] = value;
  }
  if (!['validate', 'doctor', 'generate'].includes(options.command)) {
    fail(`command must be validate, doctor or generate (got "${options.command ?? ''}")`);
  }
  if (options.command === 'generate') {
    const validTargets = [...TARGETS, 'all'];
    if (!validTargets.includes(options.target)) fail(`--target must be one of: ${validTargets.join(', ')}`);
  }
  if (options.profile !== 'all' && !PROFILES.includes(options.profile)) {
    fail(`--profile must be one of: ${PROFILES.join(', ')} (or --all)`);
  }
  return options;
}

function profileList(profile) {
  return profile === 'all' ? PROFILES : [profile];
}

function main(argv = process.argv.slice(2)) {
  let options;
  try {
    options = parseArgs(argv);
  } catch (error) {
    console.error(String(error.message));
    process.exitCode = 1;
    return;
  }

  const failures = [];
  for (const profile of profileList(options.profile)) {
    const { config, errors } = loadAndValidate(options.file, process.env, options.profile === 'all' ? null : profile);
    if (errors.length) {
      failures.push(...errors.map((line) => `[${profile}] ${line}`));
      continue;
    }
    if (options.command === 'validate') {
      console.log(`[${profile}] valid — schema, enums, URLs, fail-closed production and NODE_ENV agreement all pass`);
    } else if (options.command === 'doctor') {
      console.log(doctorReport(config, profile, process.env));
    } else if (options.command === 'generate') {
      const targets = options.target === 'all' ? TARGETS : [options.target];
      for (const target of targets) {
        const artifact = generateArtifact(config, profile, target, { env: process.env });
        const { file, content, written } = writeArtifact(profile, target, artifact, { dryRun: options.dryRun });
        console.log(`${written ? 'wrote' : 'would write'} ${path.relative(ROOT, file)} (${content.length} bytes, deterministic)`);
      }
    }
  }

  if (failures.length) {
    console.error(failures.join('\n'));
    process.exitCode = 1;
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  DEFAULT_FILE,
  GENERATED_DIR,
  PROFILES,
  TARGETS,
  PRODUCTION_ENV_REQUIREMENTS,
  loadAndValidate,
  resolvedSnapshot,
  generateArtifact,
  writeArtifact,
  doctorReport,
  parseArgs,
  main,
};
