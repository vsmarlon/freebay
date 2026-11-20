# Environment inventory — reads, selectors, fallbacks, ownership

Recorded 2026-11-20 at `dc6c911` (+ this session's changes) as the baseline for the
config-profile integration lanes (ADR 0010). "Public" means safe to compile into a
browser/mobile artifact. Everything else is server- or deployment-only.

## Backend (`nest-backend/`)

| Read | Where | Current behavior | Ownership |
|---|---|---|---|
| `NODE_ENV` | `validateEnvironment` (`src/shared/config/environment.ts`) | `development`(default)/`test`/`production`; production adds HTTPS-origins, `APP_URL`, Redis, CPF-key requirements | private (deployment) |
| `PORT` | bootstrap | default 3000 | private |
| `ALLOWED_ORIGINS` / `WEB_APP_URL` / `WEB_ALLOWED_ORIGIN` | `validateEnvironment`, `OriginGuard` | default `http://localhost:3000`; production requires HTTPS origins | private (public values, server-owned) |
| `APP_URL` | `validateEnvironment`, email/checkout links | production requires explicit HTTPS + allowlisted origin | private |
| `JWT_SECRET`, `JWT_EXPIRES_IN`, `JWT_REFRESH_EXPIRES_IN`, `JWT_BIOMETRIC_EXPIRES_IN` | auth | strong-secret validation; production enforces non-placeholder | **secret** |
| `CPF_ENCRYPTION_KEY`, `CPF_HMAC_KEY` | `validateEnvironment` | production: distinct canonical 32-byte base64 keys | **secret** |
| `DATABASE_URL` | Prisma | — | **secret** |
| `REDIS_URL`/`REDIS_HOST`/`REDIS_PORT`, `TRUST_PROXY_CIDRS` | `validateEnvironment`, throttler storage | production requires Redis | private |
| `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL` | `FcmService` | absent → FCM disabled (`fcm_disabled` diagnostics) | **secret** (project id is public-grade, key is secret) |
| `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY` | payments | test prefix in dev; publishable key is public | secret / secret / **public** |
| `SMTP_*` | email | dev defaults to Ethereal (real SMTP, disposable mailbox) — not a synthetic receipt | **secret** (host/from public-grade) |
| `TWILIO_*` | phone verification | blank → code logged to console **outside production only**; production requires real SMS | **secret** |
| `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`, `APPLE_WEB_CLIENT_ID` | OAuth audiences | at least one required or boot refuses | **public IDs** |
| `SWAGGER_ENABLED` | `swagger.setup.ts` | disabled in production regardless | private |
| `LOG_DEBUG` | `logging.interceptor.ts` | redacted body logging only when `NODE_ENV !== 'production'` | private |
| `THROTTLE_SHORT/MEDIUM/LONG_LIMIT` | `app.module.ts` | 10/60/1000 defaults | private |
| `SENTRY_DSN`, `SENTRY_RELEASE` | `sentry.ts` | blank disables Sentry | public-grade DSN, private release tag |
| `PLATFORM_FEE_PERCENT`, `DEEP_LINK_*`, `CONNECT_*` | business constants | 10% default, `freebay` scheme, BR/brl | public-grade |

## Web (`web/`)

| Read | Where | Current behavior | Ownership |
|---|---|---|---|
| `BACKEND_URL` | `vite.config.ts` seeds it; `server.mjs` + SSR loaders read `process.env` | shell env → `.env*` → `http://localhost:3000` dev default; **server-only, never a `VITE_` value**; browser calls are same-origin via the proxy (`allowedPath`, `X-Freebay-API`) | private |
| `VITE_GOOGLE_WEB_CLIENT_ID` | auth entry | blank → Google stays "not configured" | **public** |
| `VITE_APPLE_WEB_CLIENT_ID`, `VITE_APPLE_WEB_REDIRECT_URI` | auth entry | blank → Apple stays "not configured" | **public** |
| Fixture network | `web/e2e/fixture-backend.mjs` (port 3333) + Playwright configs | explicit test commands only; no runtime fallback path exists | test-only |
| `NODE_ENV` | `vite.config.ts` build mode, `server.mjs` (defaults production) | build-time selection | private |

## Flutter (`frontend/`)

| Read | Where | Current behavior | Ownership |
|---|---|---|---|
| `API_BASE_URL` | `AppConfig` via `--dart-define-from-file=.env` (`scripts/dev.cjs`) | validate: https always OK; http only non-release + loopback/private-IPv4; release with no define or invalid value **fails closed** (empty base + report) | private (public-grade URL) |
| `STRIPE_PUBLISHABLE_KEY` | `AppConfig` → Stripe SDK | required for payments UI | **public** |
| `SENTRY_DSN` | `AppConfig` | blank disables | **public-grade** |
| `GOOGLE_SERVER_CLIENT_ID` | `AppConfig` | dev/profile default baked in (public Web client matching `google-services.json`); release requires explicit define | **public** |
| `PAYMENT_MERCHANT_COUNTRY_CODE`, `APPLE_PAY_MERCHANT_ID` | `AppConfig` | wallet setup | public-grade |
| `GOOGLE_PAY_TEST_ENV`, `GOOGLE_PAY_PRODUCTION_ENABLED` | `AppConfig` | bool defines for wallet environment | private (build flag) |
| `kReleaseMode` / `kIsWeb` / platform | `AppConfig`, dev transports | release ⇒ https-only; `dev.cjs` USB transport pins `http://localhost:3000` + adb reverse | build flag |
| Firebase | `google-services.json` / `GoogleService-Info.plist` + default `Firebase.initializeApp()` | present ⇒ FCM token registration via `PATCH /users/me/fcm-token` | **public project config (no secrets)** |

## Mode selectors that already fail closed

- Backend: production validation (HTTPS origins, APP_URL, Redis, CPF keys, JWT
  strength); Swagger off in production; `LOG_DEBUG` off in production;
  `NotificationsDevController` not registered in production + handler 404 backstop.
  **Import-time caveat:** the registration check and the Swagger switch read
  `process.env.NODE_ENV` before `ConfigModule` merges `.env`, so a production
  deployment must export `NODE_ENV=production` as a real process env var; with
  `.env`-only, the dev route stays registered and the handler 404 is the safety net.
- Flutter: release build rejects http/localhost `API_BASE_URL`.
- Web: fixture network reachable only through explicit e2e commands; SSR never
  forwards browser cookies; `BACKEND_URL` never exposed to the browser bundle.
