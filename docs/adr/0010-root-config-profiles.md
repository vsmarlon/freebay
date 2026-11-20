# ADR 0010: Root config.yaml profile contract with one precedence rule

- **Status:** Accepted (CFG contract landed; BE/WEB/FL integration lanes follow)
- **Date:** 2026-11-20
- **Context:** environment-dependent behavior was spread across `nest-backend/.env*`,
  `web/.env*`, `frontend/.env` + `--dart-define` values, with mode decisions living
  implicitly in code (Swagger off in production, Twilio logging codes outside
  production, fixture web only behind the explicit e2e command, Flutter release
  failing closed on http). Each app self-configures; there was no reviewable,
  versioned statement of what each profile is supposed to do.

## Decision

Root `config.yaml` is the single versioned declaration of **non-secret**
application configuration and per-profile behavior for backend, web and Flutter.
Profiles: `development`, `test`, `production` (no staging; none exists in the repo).

Ownership boundaries:

- `config.yaml` + `scripts/config.cjs` + this ADR + `docs/config/ENV_INVENTORY.md`
  are the CFG lane's files. No other change may edit them in the same diff.
- The deployment environment/secret manager owns secrets and the deployment-owned
  public endpoints (`APP_URL`, `ALLOWED_ORIGINS`, `BACKEND_URL`,
  `VITE_GOOGLE_WEB_CLIENT_ID`, `API_BASE_URL`). The production profile declares
  them empty on purpose: validation/generation fails closed when they are absent —
  there is no localhost fallback.
- Apps keep their framework-native configuration entry points. Nothing parses YAML
  at Flutter or browser runtime; `scripts/config.cjs generate` emits deterministic,
  gitignored JSON snapshots per target under `.config-generated/`.

**The precedence rule (there is exactly one):**

1. A generated snapshot is immutable for the consuming build/run.
2. Server runtime process env may override only the documented deployment keys
   (URLs, port, credentials). Every other generated value is authoritative.
3. Selection must agree with runtime mode: a `NODE_ENV=production` process must
   use the production profile (and the reverse), or validation fails — never a
   silent fallback. Existing runtime guards stay: backend
  `validateEnvironment` (HTTPS origins, CPF keys, Redis required in production),
   Swagger disabled in production, Flutter `AppConfig.isAllowedApiBaseUrl`
   (release rejects http/localhost), the dev-only `NotificationsDevController`
   absent from production routing.

**NODE_ENV must be a real process environment variable in production.** The
dev-route registration check (`notifications.module.ts`) and the Swagger switch
read `process.env.NODE_ENV` at module-import time — before `ConfigModule`
merges `.env`. A production process that only sets `NODE_ENV` inside `.env`
still fails closed at request time (the handler 404 backstop reads ConfigService),
but the route is then registered and advertised; export `NODE_ENV=production`
properly so registration itself skips the dev controller.

## Alternatives rejected

- **Per-app dotenv duplication of profile values** — three hand-maintained copies
  drift; the failure mode (test value in production) is exactly what this contract
  exists to prevent.
- **Runtime YAML parsing in Flutter/browser** — YAML in a mobile/web artifact is
  dead weight and an attack surface; the repo rule is framework-native entry points.
- **Config validation via a new schema dependency** — root already resolves
  `yaml`; the strict validator is ~150 lines of stdlib Node. One declared
  tool-boundary dependency (`yaml`), zero schema libraries.

## Scope and follow-up

Landed with the contract: `config.yaml`, `scripts/config.cjs`
(validate/doctor/generate), `scripts/config.test.cjs` (matrix, mock-escape,
conflict, determinism, redaction negatives), inventory, gitignore. Integration is
deliberately **not** claimed: wiring generators into `scripts/dev.cjs`,
`web/vite.config.ts` and the Flutter build is the BE/WEB/FL lanes' work against
this contract. Existing launch commands keep working unchanged until then.
