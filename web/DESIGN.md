# FreeBay Web design and product contract

This document describes the current web implementation and its boundaries, not a promise of production readiness. [`../frontend/DESIGN.md`](../frontend/DESIGN.md) remains the visual-token authority; do not copy its token table here or create a competing palette.

## Product and implementation

FreeBay Web is a localized React 19 marketplace using React Router framework mode, TanStack Query, Tailwind CSS 4 and Socket.IO client. Public marketing and catalog pages support server rendering; authenticated application routes use the browser session and existing NestJS APIs. Backend authorization, pricing, inventory and transaction rules remain authoritative. UI implementation and passing isolated tests do not prove backend, provider, or deployment behavior.

The web styling follows the Digital Brutalist direction in the Flutter design contract: square geometry, tonal surfaces, restrained purple action/focus color, Space Grotesk display type, Inter body type and direct motion. Theme preference supports light, dark and system; the animated/static aurora preference and theme are stored locally. System theme follows the browser color-scheme preference, and reduced-motion preferences reduce animation. Use semantic controls, visible keyboard focus, readable contrast and responsive layouts; visual accessibility still needs browser validation.

## Routes

The registered route source is [`app/routes.ts`](app/routes.ts), composed with feature route manifests. Prefix localized routes with `/pt-BR` or `/en`.

| Area | Route examples | Source |
|---|---|---|
| Public | `/`, `/about`, `/how-it-works` | `app/routes/marketing.tsx` |
| Authentication | `/login`, `/register`, `/verify-email`, `/verify-action`, `/complete-profile`, `/forgot-password`, `/reset-password` | `app/features/auth/routes.ts` |
| Marketplace | Catalog, product detail/edit, favorites and listing editor | `app/features/marketplace/routes.ts` |
| Social | Feed, explore/search, posts, people and saved content | `app/features/social/routes.ts` |
| Stories | `/stories`, `/stories/new`, `/stories/archive`, `/stories/:userId`, `/highlights/:id` | `app/routes.ts` |
| Chat | `/messages`, `/messages/:id` | `app/routes.ts` |
| Account | Profile/settings, privacy, connections, close friends, notifications and help | `app/features/account/routes.ts` |
| Commerce | Cart/checkout, orders, sales, wallet, reviews and disputes | `app/features/commerce/routes.ts` |

Exact paths are defined by the route manifests and `app/core/routes.ts`; examples are not claims that every action or backend journey is complete. There is no admin/moderation console. Do not infer browser push, native biometric support, carrier tracking, message editing or other operations absent from the web and backend contracts.

## Authentication and session boundary

The browser supports password sign-in, Google/Apple entry when configured, explicit magic-link confirmation, profile completion and the existing code-based password recovery flow. Magic-link authentication is distinct from password recovery. The confirmation page scrubs the token from browser history and requires an explicit POST consume action; a GET preview alone is not authentication. No real email delivery or OAuth provider sign-in is established by mocked tests.

The backend owns session cookies, with HttpOnly access/refresh credentials. Browser JavaScript does not persist refresh credentials. `POST /auth/web/session/access-token` is a cookie-authenticated, strict-origin, no-store bridge that exposes the current access credential for in-memory API/socket use; it does not mint or rotate a session. Public catalog SSR deliberately does not forward browser auth cookies. Cross-tab logout notifications carry only a logout event, never credentials. See `app/core/api.ts` and `app/core/session.tsx` for the implementation contract.

Step-up UI is present for password-backed reauthentication where supported; provider-only reauthentication is not established. Sensitive actions remain subject to backend proof and authorization. Treat active auth integration work and browser journeys as unverified until their current reports record a clean run.

## API, rendering and deployment

Browser API calls use the same-origin API paths. In development, Vite proxies API and Socket.IO paths to the backend on port `3000`. Public product/category SSR uses server-only `BACKEND_URL`; it does not use browser credentials. The custom production entry is `server.mjs` and listens on `PORT` (default `3000`).

Deploy behind a reverse proxy that routes the web app and backend under the same public origin, preserving `/auth/web/session` so the refresh cookie path works. Configure HTTPS, trusted/allowed web origins, and provider callback origins in the backend and identity-provider consoles. Keep server credentials out of `VITE_*` variables. See [`README.md`](README.md) for local setup and the exact browser OAuth variable names.

## Not established

Code presence and isolated tests are not release evidence. Current browser contract tests use synthetic fixtures and do not verify a real database, email delivery, OAuth, payment settlement, live sockets, backend authorization, device behavior or production deployment. Commerce remains incomplete in identified areas including role affordances, order-thread discovery/review display, delivery/tracking and real settlement. Refer to [`../docs/FEATURE_TRUTH.md`](../docs/FEATURE_TRUTH.md) and dated web test reports for verified limits; do not describe this web client as feature-complete or production-ready based on source alone.
