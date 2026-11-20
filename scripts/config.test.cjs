const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const configCli = require('./config.cjs');

function withTempFile(content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'freebay-config-'));
  const file = path.join(dir, 'config.yaml');
  fs.writeFileSync(file, content, 'utf8');
  return file;
}

const DEV_ENV = { NODE_ENV: 'development' };
const PROD_ENV = {
  NODE_ENV: 'production',
  ALLOWED_ORIGINS: 'https://freebay.example',
  APP_URL: 'https://freebay.example',
  BACKEND_URL: 'https://api.freebay.example',
  VITE_GOOGLE_WEB_CLIENT_ID: 'example-client-id',
  API_BASE_URL: 'https://api.freebay.example',
};

test('committed config.yaml validates development and test profiles as-is', () => {
  for (const profile of ['development', 'test']) {
    const { config, errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, DEV_ENV, profile);
    assert.equal(errors.length, 0, `${profile}: ${errors.join('; ')}`);
    assert.equal(config.profiles[profile].backend.storage, 'local-disk');
    assert.equal(config.profiles[profile].web.network === 'fixture', profile === 'test');
  }
});

test('production profile fails closed without deployment environment values', () => {
  const { errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, { NODE_ENV: 'production' }, 'production');
  const missing = errors.filter((line) => line.includes('deployment-owned'));
  assert.deepEqual(
    missing.map((line) => line.match(/profiles\.production\.\w+\.\w+/)?.[0]),
    [
      'profiles.production.backend.allowedOrigins',
      'profiles.production.backend.appUrl',
      'profiles.production.web.backendOrigin',
      'profiles.production.web.googleWebClientId',
      'profiles.production.flutter.apiBaseUrl',
    ],
  );
  assert.ok(errors.length >= missing.length);
});

test('production profile validates when the deployment environment supplies every endpoint', () => {
  const { errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, PROD_ENV, 'production');
  assert.equal(errors.length, 0, errors.join('; '));
});

test('a mock mode under the production profile is rejected instead of silently accepted', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      payments: stripe-live', '      payments: mock'));
  const { errors } = configCli.loadAndValidate(file, PROD_ENV);
  assert.ok(errors.some((line) => line.includes('mock or debug escape rejected') && line.includes('payments must be "stripe-live"')));
});

test('non-https production URLs are rejected', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      appUrl: \'\'', '      appUrl: http://localhost:5173'));
  const { errors } = configCli.loadAndValidate(file, PROD_ENV);
  assert.ok(errors.some((line) => line.includes('every configured URL must use https')));
});

test('NODE_ENV disagreeing with the selected profile is a loud conflict', () => {
  const devAgainstProd = configCli.loadAndValidate(configCli.DEFAULT_FILE, { NODE_ENV: 'development' }, 'production');
  assert.ok(devAgainstProd.errors.some((line) => line.includes('NODE_ENV must be production for the production profile (got development)')));
  const prodAgainstDev = configCli.loadAndValidate(configCli.DEFAULT_FILE, { NODE_ENV: 'production' }, 'development');
  assert.ok(prodAgainstDev.errors.some((line) => line.includes('NODE_ENV=production conflicts with the selected development profile')));
});

test('unknown keys are listed and rejected instead of ignored', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      port: 3000', '      port: 3000\n      emailApi: smtp'));
  const { errors } = configCli.loadAndValidate(file, DEV_ENV);
  assert.ok(errors.some((line) => line.includes('unknown keys emailApi')));
});

test('secret-looking keys are rejected outright wherever they appear', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      port: 3000', '      port: 3000\n      JWT_SECRET: hunter2'));
  const { errors } = configCli.loadAndValidate(file, DEV_ENV);
  assert.ok(errors.some((line) => line.includes('JWT_SECRET: secrets never belong in config.yaml')));
});

test('invalid enum values are rejected with the allowed set', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      email: smtp-ethereal', '      email: pigeon-post'));
  const { errors } = configCli.loadAndValidate(file, DEV_ENV);
  assert.ok(errors.some((line) => line.includes('profiles.development.backend.email must be one of: smtp-ethereal, mock, real')));
});

test('invalid YAML fails with a parse error instead of half-loading', () => {
  const file = withTempFile('profiles: [unclosed');
  const { errors } = configCli.loadAndValidate(file, DEV_ENV);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /YAML parse error/);
});

test('generate output is deterministic and never embeds secret material', () => {
  const { config, errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, DEV_ENV, 'development');
  assert.equal(errors.length, 0);
  const first = configCli.generateArtifact(config, 'development', 'flutter', { env: DEV_ENV });
  const second = configCli.generateArtifact(config, 'development', 'flutter', { env: DEV_ENV });
  assert.deepEqual(JSON.parse(JSON.stringify(first)), JSON.parse(JSON.stringify(second)));
  assert.equal(first.values.apiBaseUrl, 'http://localhost:3000');
  assert.equal(JSON.stringify(first).includes('SECRET'), false);
});

test('generate prefers deployment environment values over yaml placeholders in production', () => {
  const { config, errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, PROD_ENV, 'production');
  assert.equal(errors.length, 0);
  const artifact = configCli.generateArtifact(config, 'production', 'flutter', { env: PROD_ENV });
  assert.equal(artifact.values.apiBaseUrl, 'https://api.freebay.example');
  assert.deepEqual(artifact.deploymentEnv, ['API_BASE_URL']);
});

test('dry-run generation writes nothing while a real write lands atomically', () => {
  const { config, errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, DEV_ENV, 'development');
  assert.equal(errors.length, 0);
  const artifact = configCli.generateArtifact(config, 'development', 'web', { env: DEV_ENV });

  // A previous real generate may have left the artifact on disk; the dry-run
  // claim must not depend on that leftover state.
  fs.rmSync(path.join(configCli.GENERATED_DIR, 'development.web.json'), { force: true });

  const dry = configCli.writeArtifact('development', 'web', artifact, { dryRun: true });
  assert.equal(dry.written, false);
  assert.equal(fs.existsSync(dry.file), false);

  const written = configCli.writeArtifact('development', 'web', artifact, { dryRun: false });
  assert.equal(written.written, true);
  assert.equal(fs.readFileSync(written.file, 'utf8'), written.content);
  fs.rmSync(written.file);
});

test('doctor output reports deployment keys as set without echoing their values', () => {
  const { config, errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, DEV_ENV, 'development');
  assert.equal(errors.length, 0);
  const report = configCli.doctorReport(config, 'development', { ...DEV_ENV, DATABASE_URL: 'postgresql://secret-user:secret-pass@localhost/db' });
  assert.match(report, /DATABASE_URL: set \(value hidden\)/);
  assert.equal(report.includes('secret-user'), false);
  assert.equal(report.includes('secret-pass'), false);
});

test('secret-looking values are rejected under benign keys too', () => {
  const smuggled = fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace("      googleWebClientId: ''        # fromEnv: VITE_GOOGLE_WEB_CLIENT_ID (public id)", "      googleWebClientId: sk_live_51smuggled000000")
    .replace("      appleWebClientId: ''         # fromEnv: VITE_APPLE_WEB_CLIENT_ID (public id)", "      appleWebClientId: -----BEGIN RSA PRIVATE KEY-----");
  const { errors } = configCli.loadAndValidate(withTempFile(smuggled), PROD_ENV, 'production');
  assert.ok(errors.some((line) => line.includes('profiles.production.web.googleWebClientId: value looks like a Stripe secret key')));
  assert.ok(errors.some((line) => line.includes('profiles.production.web.appleWebClientId: value looks like private key material')));
});

test('production endpoints on loopback or private addresses are rejected', () => {
  const file = withTempFile(fs.readFileSync(configCli.DEFAULT_FILE, 'utf8')
    .replace('      appUrl: \'\'', '      appUrl: https://localhost:3000'));
  const { errors } = configCli.loadAndValidate(file, PROD_ENV, 'production');
  assert.ok(errors.some((line) => line.includes('is a loopback or private address')));
});

test('selecting the production profile with NODE_ENV unset is a loud conflict', () => {
  const { errors } = configCli.loadAndValidate(configCli.DEFAULT_FILE, {
    ALLOWED_ORIGINS: 'https://freebay.example',
    APP_URL: 'https://freebay.example',
    BACKEND_URL: 'https://api.freebay.example',
    VITE_GOOGLE_WEB_CLIENT_ID: 'example-client-id',
    API_BASE_URL: 'https://api.freebay.example',
  }, 'production');
  assert.ok(errors.some((line) => line.includes('NODE_ENV must be production for the production profile (got unset)')));
});

test('argument parsing rejects unknown options, bad targets and bad profiles', () => {
  assert.throws(() => configCli.parseArgs(['validate', '--wat']), /unknown option/);
  assert.throws(() => configCli.parseArgs(['generate', '--profile', 'development', '--target', 'mobile']), /--target must be one of/);
  assert.throws(() => configCli.parseArgs(['validate', '--profile', 'staging']), /--profile must be one of/);
  assert.throws(() => configCli.parseArgs(['deploy']), /command must be validate, doctor or generate/);
  assert.equal(configCli.parseArgs(['generate', '--profile', 'development', '--target', 'all']).target, 'all');
});
