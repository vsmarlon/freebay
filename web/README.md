# FreeBay Web

React Router web client for FreeBay. Public marketing and catalog routes are localized at `/pt-BR` and `/en`; account and marketplace routes live in the same app. The web UI calls the existing NestJS API and does not replace its authorization or business rules.

## Local development

Requirements: Node.js/npm, a running NestJS backend, and the repository's existing environment configuration.

```sh
cd web
npm ci
npm run dev
```

Or from the repository root after installing `web/` dependencies:

```sh
npm run web:dev
```

Vite listens on port `5173` and proxies API and Socket.IO paths to `http://localhost:3000`. Start the backend on that address, or adjust `web/vite.config.ts` for a different local target. Public product/category server rendering requires server-only `BACKEND_URL` to point at the backend. Do not expose it as a `VITE_` variable.

## OAuth and email configuration

Set browser OAuth values in `web/.env.local` (the exact names are read by `app/features/auth/oauth-buttons.tsx`):

```dotenv
VITE_GOOGLE_WEB_CLIENT_ID=
VITE_APPLE_WEB_CLIENT_ID=
VITE_APPLE_WEB_REDIRECT_URI=
```

These are public client configuration, not secrets. Configure the Google client with the web origin and matching backend audience (`GOOGLE_WEB_CLIENT_ID`). Configure Apple with a registered Services ID, HTTPS return URL/domain and matching web client ID; Apple web sign-in is not expected to work on localhost or an IP address. Keep the native Apple client ID separate. The backend also needs its trusted web origin and working email sender/provider configuration for magic-link delivery. Never put provider secrets, backend credentials, or signing keys in `VITE_*` variables. OAuth provider sign-in and real email delivery have not been verified by the browser fixture runs.

For browser hosted-checkout and Connect returns, backend `APP_URL` and (when set) `DEEP_LINK_HOST` must point to the public web origin, not the backend's internal hostname; production `APP_URL` must also be in the backend's trusted origins. The web app accepts only the source-configured legacy callbacks `/payments/success`, `/payments/cancel`, `/wallet/connect/refresh`, and `/wallet/connect/return`, then redirects to the locale-prefixed pages while preserving the provider query. The local backend `.env` currently sets `APP_URL=http://localhost:3000` (the backend origin), so local provider returns do not prove or reach the web app unless configured for its origin. Set Apple `VITE_APPLE_WEB_REDIRECT_URI` to the exact HTTPS URL registered for the web Services ID; the browser flow uses the configured URI with the Apple popup, and no speculative Apple callback alias is added.

## Checks

From `web/`:

```sh
npm run typecheck
npm run lint
npm test
npm run test:e2e
npm run build
```

`npm run start` serves the production build on port `3001` by default and proxies the existing API and Socket.IO paths to server-only `BACKEND_URL` (default `http://localhost:3000`). Set `PORT` or `BACKEND_URL` as needed. This keeps browser API calls and the refresh cookie on the web origin without rewriting `/auth/web/session`; configure HTTPS and the backend's allowed/trusted origin for deployment.

## Current boundaries

- The app has PT-BR/English catalogs, localized marketing/auth, marketplace, social, stories, chat, account and commerce route modules. The route registry in `app/routes.ts` is authoritative.
- Browser sessions use HttpOnly cookies. The access-token exchange is a same-origin `POST` bridge for in-memory API/socket use; access tokens are not stored in local storage. Public catalog SSR does not forward browser auth cookies.
- Magic-link confirmation is an explicit browser flow; it is not password recovery. Email delivery, OAuth providers, real backend journeys, payment settlement and production deployment still require independent verification.
- Admin/moderation console, native biometrics, browser push, carrier tracking and unsupported backend operations are not implied by the mobile app or by route names.

See [`DESIGN.md`](DESIGN.md) for the web interaction contract and [`../docs/FEATURE_TRUTH.md`](../docs/FEATURE_TRUTH.md) for code-verified capability limits and evidence.
