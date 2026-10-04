# Store compliance backend privacy/lifecycle slice

**Revision:** `c9808b1` plus integrated dirty working tree; no commit created. Existing unrelated dirty work was preserved. The Apple auth use-case and provider specs were owned by another tester and were not edited here.

## Implemented

- `GET /users/me/export` now returns explicit per-model Prisma projections for the owner's profile, products/images, posts/comments, orders/transactions, wallet, limited Connect status, reviews/images, authored direct/order-chat messages, notifications, submitted report categories, order-related dispute dates, stories, saved posts, likes, shares, favorites, cart, follows, followers, and blocks in both directions. Response includes `exportedAt`, `scope.included`, and `scope.excluded`. No raw broad model reads remain. Provider IDs/secrets, other users' contact/CPF data, payment-provider payloads/identifiers, moderation internals, free-text report/dispute details, notification payloads, media bytes, and access logs are excluded. User-authored attachment/image URLs may be present; media bytes are not.
- Session JWTs now carry signed `authenticatedAtMs` at original issuance. Mobile and web refresh preserve that original claim; legacy refresh tokens without it remain without it. `PATCH /users/me/deletion/cancel` now requires a non-future auth timestamp no older than five minutes and returns `FRESH_AUTH_REQUIRED` (401) otherwise. No client timestamp is accepted.
- Existing `nest-backend/legal/delete-account.html` is now a functional but explicitly unpublished draft. It requests an account-deletion-purpose magic link using existing `/auth/web/magic-link/request`, consumes it using existing cookie-session endpoint, erases the fragment immediately, then requires a separate checkbox/button confirmation before requesting deletion. Token links use the same-origin legal URL fragment, not a query string. Unknown addresses remain generic and an unknown account cannot be created by consuming a deletion-purpose token. Web deletion/cancellation endpoints are strict-origin guarded and use the existing cookie session; no bearer token is stored in browser storage.
- Legal copy now describes the 30-day window, fresh-auth cancellation, blockers, non-restoration of paused listings, and limited existing purge/retention behavior rather than claiming immediate/full erasure. Controller identity/contact and retention legal review remain conspicuously pending. Privacy copy discloses scoped export and Apple auth/credential handling.

## Routes/configuration for frontend integration

- Request email: `POST /auth/web/magic-link/request` body `{ email, consent: true, locale, purpose: 'account-deletion' }`; response remains generic `{ sent: true }`. Trusted `Origin` must pass existing `StrictOrigin` configuration. `RESEND_API_KEY` and verified sender configuration are required for delivery.
- Consume token: `POST /auth/web/magic-link/consume` body `{ token }`; returns user projection and sets existing HttpOnly web-session cookies. Link token comes from `#token=...`; page removes fragment before network use.
- Explicit deletion: `DELETE /users/me/web`; pending cancellation: `PATCH /users/me/web/deletion/cancel`. Both require an authenticated same-origin web cookie session. Normal mobile API routes remain unchanged.
- Existing public resource path is `/legal/delete-account.html` (static root configured by Nest `ServeStaticModule`). Public publication is blocked pending controller/contact details, legal review, trusted-origin deployment configuration, email delivery, and Apple private-relay verification. The page does not claim that email was actually delivered.

## Test-first evidence

- Cancellation stale-session test RED: `npm test -- --runInBand src/modules/users/usecases/cancel-account-deletion.usecase.spec.ts` failed on the intended assertion: `Expected: true; Received: false` for stale auth being rejected. GREEN is included in the final focused run.
- Export projection test RED: focused test failed because the repository query received `{ where: { sellerId: 'u1' } }` without a `select`; this was a behavioral assertion, not a compile/setup failure. GREEN is included in the final focused run.
- Refresh-auth-age test RED: focused test expected `generate('u1', 'USER', authenticatedAtMs)` but received only the two original arguments. GREEN is included in the final focused run.
- Deletion-purpose token test RED: focused test expected repository consumption with `allowRegistration=false` but received only the original two arguments. GREEN is included in the final focused run.
- Email URL test was added after the initial test work; invalid-origin and fragment URL behavior pass in focused/final suites.
- Focused command: `npm test -- --runInBand src/modules/users/data/repositories/user-data-export.repository.spec.ts src/modules/users/usecases/cancel-account-deletion.usecase.spec.ts src/modules/auth/usecases/refresh-mobile-session.usecase.spec.ts src/modules/auth/usecases/refresh-web-session.usecase.spec.ts src/modules/auth/services/session-token.service.spec.ts src/modules/auth/usecases/consume-magic-link.usecase.spec.ts src/modules/auth/usecases/request-magic-link.usecase.spec.ts src/modules/auth/services/resend.service.spec.ts src/modules/auth/auth.controller.spec.ts` — **9 suites, 37 tests passed**.

## Verification

- `npx tsc --noEmit` — passed (no output).
- `npm run lint` — passed (zero warnings).
- `npm test -- --runInBand` — passed: **102 suites, 643 tests**. Expected error logs from existing failure-path tests were emitted; Jest exited successfully.
- `npm run build` — passed.
- `npm run test:safety` — passed: **5/5**.
- No database, Prisma synchronization, migration, provider, public-hosting, browser, or frontend commands/calls were performed. Prisma schema rollout and actual Apple/Google/email behavior remain unverified.

## Remaining owner/reviewer gates

- Review legal draft and supply verified controller/company/contact details and approved retention language before publication.
- Confirm API/public-web trusted origins and Resend sender/API configuration. Prove delivery, including Apple private relay, in the intended environment before saying the public request works in production.
- Frontend owner should consume the web cookie session and expose a reauthentication path when cancellation returns `FRESH_AUTH_REQUIRED`; the static draft allows a new magic-link request after 401.
- Confirm generated Prisma client/runtime schema deployment through the owner's approved migration workflow; no database command was run here.
- Existing purge does not remove every associated message/media record; this report and legal draft state that limit rather than claiming complete erasure.
