# FreeBay — Pre-live test plan

Created **2026-11-07**. This is the execution plan for proving the app before a
production launch. It is not evidence by itself. Mark a scenario **PASS** only
with the artifact named in its row.

## 0. Setup completed on 2026-11-07 (dev)

- Backend uses Stripe **test mode** from account `acct_1UCqKMCp71FGNzMg`
  ("freebay"). Backend secret and Flutter publishable key now belong to the
  same account. The previous pair was cross-account and could not confirm
  PaymentIntents.
- Stripe CLI forwards `payment_intent.*`, `checkout.session.*`, refund/dispute
  and Connect events to `http://localhost:3000/payments/webhook`. Signed
  events return 200.
- Fixed `main.ts`: the extra `express.json()` parser consumed the body before
  Nest's raw-body parser, so every webhook failed signature verification.
- Fixed Connect account creation/onboarding to request the Stripe-required
  `configuration.merchant.card_payments` capability alongside
  `stripe_balance.stripe_transfers`.
- Dev CPF encryption keys provisioned and a valid test CPF set on the seeded
  buyer `marcos_tech`.
- Resend is configured with the test sender `onboarding@resend.dev` and the
  account owner address `marlonstein260404@gmail.com` because no sending domain
  is verified yet.
- `APP_URL`/`WEB_APP_URL` corrected to the web origin (`http://localhost:5173`)
  so Checkout returns to the app instead of the API.
- **Runtime-proven:** web login, feed, product page, order creation, CPF gate,
  Stripe Checkout with `4242 4242 4242 4242`, signed webhook delivery, order
  moved to **Confirmado** with escrow **Retido**; Connect account created for
  `marcos_tech` and Stripe-hosted onboarding opened from the web wallet.

Still blocked without owner action: live Stripe activation (identity/product
activation), domain purchase, hosting accounts, Firebase/FCM, Apple Developer,
Google Web OAuth client, Sentry, and R2/S3 storage.

### Findings observed during setup

- The web buy page still renders two untranslated keys:
  `commerce.cart.title` and `commerce.orders.title`.
- The seeded buyer wallet shows a **R$ 1.500,00** balance that is not derived
  from Stripe. Treat it as fixture data and reconcile before any live claim.
- The test Connect account for `marcos_tech` is **Restrita** with 22
  requirements; the hosted onboarding must be completed in test mode before a
  transfer-ready state can be proven.
- The web checkout return URL is now `http://localhost:5173`; the previous
  `http://localhost:3000/payments/success` 404 was an env misconfiguration.

### Reproduce the dev stack

```powershell
# 1. Backend (port 3000)
cd nest-backend
npm run build
node dist/src/main

# 2. Web (port 5173)
cd ..\web
npm run dev

# 3. Stripe webhook forwarding (separate terminal)
$env:STRIPE_API_KEY = '<test secret key from nest-backend/.env>'
stripe listen --forward-to http://localhost:3000/payments/webhook `
  --forward-connect-to http://localhost:3000/payments/webhook

# 4. Flutter on a device (frontend/.env carries the API and Stripe key)
cd ..\frontend
flutter run --dart-define-from-file=.env
```

`stripe listen --print-secret` gives the signing secret for
`STRIPE_WEBHOOK_SECRET`. If the CLI rotates it, update `.env` and restart the
backend. Never commit `.env` or the signing secret.

## 1. Exit criteria

The release is not shippable until all of these are true:

1. Every **P0** scenario below passes in the dev environment and again in a
   staging environment that mirrors production configuration.
2. The live-mode smoke section passes with a small real charge, real refund and
   real seller transfer; provider IDs and ledger rows are reconciled.
3. No open P0/P1 defect and no unexplained crash in Android/iOS release builds.
4. Backend gates: `tsc`, lint, unit, integration, E2E, build, safety.
5. Web gates: `tsc`, lint, tests, production build, real-backend E2E.
6. Flutter gates: format, analyze, release APK/AAB and iOS archive builds,
   physical-device passes.
7. Store checklist in `docs/STORE_RELEASE_CHECKLIST.md` is fully evidenced.
8. Final whole-repository security review passes; no secrets in the client or
   repository.

## 2. Environments

| Environment | Web | API | PostgreSQL | Redis | Stripe | Email | Media |
|---|---|---|---|---|---|---|---|
| Dev (today) | localhost:5173 | localhost:3000 | local | local | test mode + CLI forwarding | Resend test sender | local disk |
| Staging | HTTPS host | HTTPS host | managed | managed | test mode, dashboard webhook | verified domain | R2/S3 |
| Live | app domain | api domain | managed + backup | managed | live mode | verified domain | R2/S3 |

### Free / low-cost hosting option

For a **staging** environment, all of this can run on free tiers:

- Web: **Netlify free** or **Cloudflare Pages free** (commercial use allowed;
  check the current adapter for React Router SSR). Vercel Hobby is free but is
  restricted to non-commercial personal use, so a marketplace needs Pro.
- API: **Render free web service** (512 MB, spins down after inactivity,
  750 h/month). Expect 30–60 s cold starts; not suitable for launch traffic.
- PostgreSQL: **Neon free** (0.5 GB, autosuspend) or Supabase free (pauses when
  idle).
- Redis: **Upstash free** (10k commands/day).
- Media: **Cloudflare R2 free** (10 GB, free egress).
- Email: **Resend free** (3k/month, 100/day, verified domain required).
- Push: **Firebase free**.
- Errors: **Sentry free**.

For **production**, budget roughly USD 25–45/month: Render/Railway API +
managed Postgres + Upstash pay-as-you-go + R2 + domain. Free tiers are for
staging only because of cold starts, storage limits and idle pauses.

## 3. Accounts and fixtures

| Fixture | Value / source | Notes |
|---|---|---|
| Buyer | `marcos@freebay.app` / `Freebay@2026` | Seeded; CPF set for dev |
| Seller 1 | `carol@freebay.app` / `Freebay@2026` | Seeded, verified |
| Seller 2 | `lucas@freebay.app` / `Freebay@2026` | Seeded |
| Admin | `admin@freebay.app` / `Freebay@2026` | Staff/moderation routes |
| Stripe success card | `4242 4242 4242 4242`, any future expiry, any CVC | Test mode |
| Stripe decline card | `4000 0000 0000 0002` | Declined |
| Stripe 3DS card | `4000 0027 6000 3184` | Requires authentication |
| Connect test account | Created per seller during onboarding | Test mode |
| Connect onboarding phone | "Use test phone number" | Stripe-hosted |
| Email inbox | `marlonstein260404@gmail.com` (Resend owner) | Only address the test sender can reach |
| Webhook endpoint | `http://localhost:3000/payments/webhook` via Stripe CLI | Stable CLI secret |

Reset between suites: cancel stale orders, expire checkout sessions, clear cart,
and reseed only through the documented dev workflow. Never seed production.

## 4. Evidence rules

For every scenario record:

- date, revision (`git rev-parse HEAD`) and dirty-file summary;
- environment (dev/staging/live) without credentials;
- exact steps and fixture IDs (order, product, conversation, account);
- expected vs actual;
- screenshot or screen recording under `docs/test-runs/<date>/` (Flutter
  evidence under `docs/device-runs/<date>/`);
- provider evidence: Stripe event ID, PaymentIntent ID, transfer ID, refund ID;
- backend request ID and relevant log lines (redact tokens, CPFs, card data);
- PASS / FAIL / BLOCKED. A blocked run is not a pass.

## 5. Scenario matrix

Priorities: **P0** blocks launch, **P1** blocks the affected journey, **P2**
polish.

### A. Auth and session

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| A1 | P0 | Register with email, verify email, login | Account created; verification email arrives; login works | Screen + email + DB row |
| A2 | P0 | Login with email and with `@username` | Both succeed; wrong password is generic | Two sessions |
| A3 | P0 | Refresh, logout, logout all devices, account switch | Old refresh token fails; no stale wallet/chat data | API trace + screen |
| A4 | P0 | Password reset | Token single-use, expires, new password works | Email + login |
| A5 | P1 | Google login (Android/iOS) | Provider identity links once; no duplicate account | Device + DB |
| A6 | P1 | Apple login (iOS) | Token validated; revocation on deletion | Device + Apple response |
| A7 | P1 | Biometric enrollment/login | Consent required; cancel/off/no-enrollment paths safe | Device video |
| A8 | P1 | Session expiry mid-journey | Re-auth prompt; no data loss; checkout resumes | Screen + order |

### B. Profile, CPF and onboarding

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| B1 | P0 | Welcome gate first login | Completes or skips; does not reappear incorrectly | Screen |
| B2 | P0 | Edit display name, username, bio, city/state | Persists after reload; validation rejects bad input | Before/after |
| B3 | P0 | Set CPF with verification code | Code single-use; CPF masked on read; duplicate CPF rejected | API + masked UI |
| B4 | P1 | Avatar and cover upload, crop, cancel, replace | Only confirmed media persists | Device video |
| B5 | P1 | Follow/unfollow, followers/following counts | Immediate update, rollback on failure | Two accounts |
| B6 | P1 | Account deletion request and export | Deletion window/blockers explained; export contains user data | Email + screen |
| B7 | P1 | Privacy, theme and background preferences | Persist across restart on web and device | Reload/relaunch |

### C. Discovery, catalog and search

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| C1 | P0 | Feed first open, pagination, refresh | No blank state; no duplicates; end reached | Video + trace |
| C2 | P0 | Product detail from feed, search and share link | Correct seller, price, stock and images | Screens |
| C3 | P0 | Search products/users, empty and error states | Stable results; retry works | Screens |
| C4 | P0 | Category and price filters, apply/cancel | Requests only after apply; cancel restores previous filter | Network log |
| C5 | P1 | Favorites and saved posts are distinct | Save/unsave persists; lists do not mix | Two lists |
| C6 | P1 | Following feed only followed accounts | Unfollow removes content | Two accounts |
| C7 | P1 | Profile posts cursor pagination | Append without flash or duplicates | Video |

### D. Cart and checkout — web

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| D1 | P0 | Buy one item as a non-owner | Order created pending; Checkout opens | Order ID |
| D2 | P0 | Missing CPF | Specific profile message; no charge | Screen |
| D3 | P0 | Pay with `4242` | Stripe success; return to app; order **Confirmado**; escrow **Retido** | PI + event + order |
| D4 | P0 | Declined card | Order stays pending; retry possible | Event + screen |
| D5 | P0 | 3DS card | Challenge completes; settlement correct | Screen + event |
| D6 | P0 | Cancel Checkout | Return to cancel page; order payable again | Screen |
| D7 | P0 | Webhook replay and out-of-order delivery | Idempotent; no double credit | Replay output |
| D8 | P1 | Multi-seller cart | One payment, independent order allocations | Order rows |
| D9 | P1 | Stock race: two buyers, one item | One succeeds; other gets deterministic out-of-stock | Two sessions |
| D10 | P1 | Refresh/close during Checkout | Recovery returns to same pending payment | Screen + order |

### E. Cart and checkout — Flutter

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| E1 | P0 | Native PaymentSheet with test card | Sheet confirms; webhook settles; no web redirect | Device video |
| E2 | P0 | PaymentSheet cancel/failure | Order pending; retry safe | Device video |
| E3 | P0 | 3DS on device | Challenge returns to app; settlement correct | Device video |
| E4 | P1 | Native wallet payment (Google/Apple Pay) | Correct merchant; production build tested in sandbox | Device + provider |
| E5 | P1 | Cart quantity, stock and seller split | Server-confirmed amounts; integer cents | Cart + order |
| E6 | P1 | Deep link return from Checkout | Correct order, no duplicate | Device video |

### F. Orders, escrow, refunds and disputes

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| F1 | P0 | Seller sees sale; buyer sees purchase | Same order, correct counterparties | Two accounts |
| F2 | P0 | Meetup handover: seller marks delivered, buyer confirms | Escrow releases only after buyer confirmation | Order timeline |
| F3 | P0 | Cancel before payment and after payment | Correct stock and refund paths | Order + refund |
| F4 | P0 | Full and partial refund | Ledger reverses correctly; no double refund | Refund ID + ledger |
| F5 | P0 | Open dispute, evidence, close | Funds held; decision releases/refunds once | Dispute screens |
| F6 | P1 | Order chat and timeline | Every status change appears; no PII leak | Screen |
| F7 | P1 | Review after completion | One review per order; seller rating updates | Screen + DB |

### G. Wallet, Connect, transfers and payouts

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| G1 | P0 | New seller starts onboarding | Account created (recipient + merchant), hosted link opens | Account ID |
| G2 | P0 | Onboarding incomplete | Status **Restrita**; requirements listed; no transfer | Wallet screen |
| G3 | P0 | Onboarding completed in test mode | Status becomes transfer-ready after fresh capability check | Stripe API + screen |
| G4 | P0 | Transfer after delivery confirmation | One transfer, exact integer cents, transfer group + metadata | Transfer ID |
| G5 | P0 | Crash before/after transfer call | Reconciliation creates no duplicate | Replay logs |
| G6 | P0 | Refund/dispute after transfer | Reversal once; ledger consistent | Reversal ID |
| G7 | P0 | Express dashboard link | Opens correct seller account | Screen |
| G8 | P1 | Account switch/logout | No seller data leakage | Two accounts |
| G9 | P1 | Payout vs transfer wording | UI never claims money reached a bank | Copy review |

### H. Chat, social and stories

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| H1 | P0 | Product inquiry creates one conversation per product+pair | Reopens same thread; different product creates new thread | Chat IDs |
| H2 | P0 | Seller folders and unread ordering | Buyer/seller see correct interlocutor folders | Two accounts |
| H3 | P0 | Send text, image, audio, location; reload | Persists; recipient sees same payload | Device video |
| H4 | P0 | Read receipts, mute, archive, search | Real-time and persistent | Two devices |
| H5 | P1 | Comments, replies, restricted-comment approval | Owner approves; outsider cannot read private media | Screens |
| H6 | P1 | Create story; refresh; close friends | Story appears; audience restrictions hold | Screens |
| H7 | P1 | Block/report user | Content hidden both directions; report stored | Admin view |
| H8 | P1 | View-once media | Opens once per recipient; persists correctly | Device video |

### I. Media, editor and uploads

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| I1 | P0 | Upload avatar, product image, post image, story | Correct MIME/size; durable URL | Files + DB |
| I2 | P0 | Chat image editor: crop, draw, cancel, send | Cancel uploads nothing; send creates one message | Device video |
| I3 | P0 | Video editor export | Preview and export agree; audio/video in sync | Device video |
| I4 | P1 | Save image/video to gallery | Permission flow; no path traversal | Device video |
| I5 | P1 | Oversized/invalid file | Rejected with safe error; no partial file | API trace |

### J. Notifications, push and deep links

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| J1 | P0 | In-app notifications real-time | Inbox updates without reload | Two devices |
| J2 | P0 | Push foreground, background, killed | Delivered once; correct title/body | Device + FCM log |
| J3 | P0 | Push tap destination | Correct order/chat/product; auth respected | Device video |
| J4 | P1 | Multiple devices, token rotation, logout | Old token removed; no cross-user push | DB + devices |
| J5 | P1 | Notification preferences | Muted thread sends no push | Two devices |

### K. Moderation, admin, privacy and support

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| K1 | P0 | Admin moderation list/report actions | Authorized staff only; audit trail | Admin session |
| K2 | P0 | Blocked user cannot reach profile/media/chat | 403/empty; no metadata leak | Outsider session |
| K3 | P0 | Account deletion and public deletion URL | In-app path works; public URL opens without login | Screen + URL |
| K4 | P1 | Bug report and help flows | Report stored; no secrets/PII in logs | Admin view |
| K5 | P1 | Data retention and legal pages | Published URLs match approved text | URLs |

### L. Non-functional

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| L1 | P0 | Accessibility: screen reader, focus, contrast, text scale | All primary journeys usable | Device + audit |
| L2 | P0 | Performance: cold/warm feed, search, images, scroll | Baseline and post traces; no unexplained jank | Trace files |
| L3 | P0 | Offline/reconnect: feed, chat, checkout | No data loss; retry safe; no duplicate charge | Video + logs |
| L4 | P0 | Security: authz on every object, upload, webhook, rate limits | No IDOR; signatures verified; limits enforced | Security report |
| L5 | P0 | Observability: Sentry, request IDs, health/readiness, alerts | Errors traceable; probes correct | Screens |
| L6 | P0 | Backup and restore | Restore drill succeeds; RPO/RTO recorded | Restore log |
| L7 | P1 | Rollback | Previous backend/API version can be restored | Rollback log |

### M. Store and release

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| M1 | P0 | Android release AAB | Target API current; signed; installs clean | AAB + device |
| M2 | P0 | iOS archive | Signed; entitlements; TestFlight install | Archive + device |
| M3 | P0 | Reviewer account and instructions | Reviewer can complete login and key journeys | Store notes |
| M4 | P0 | Data safety / App Privacy | Matches actual SDK traffic | Store forms |
| M5 | P0 | Account deletion URL and legal pages | Public, stable, correct | URLs |
| M6 | P1 | Store metadata and screenshots | Reflect current UI and meetup-only scope | Store listing |

### N. Live-mode smoke (after staging passes)

| ID | P | Scenario | Expected | Evidence |
|---|---|---|---|---|
| N1 | P0 | Live Stripe activation and product activation | Platform can charge and pay out | Dashboard |
| N2 | P0 | One small real charge | Captured; webhook settles order | PI + order |
| N3 | P0 | Refund the live charge | Refund succeeds; ledger reverses | Refund ID |
| N4 | P0 | One real seller onboarding + transfer | Requirements clear; transfer reaches seller balance | Account + transfer |
| N5 | P0 | Bank payout distinction | Transfer ≠ payout; UI wording correct | Dashboard |
| N6 | P0 | Live webhook endpoint with production secret | Signed events 200; no replay duplicates | Event log |
| N7 | P0 | Monitoring and alerting | Error/charge failures alert the owner | Alert |

## 6. Stripe-specific rules to verify

1. **One account everywhere.** Backend secret key, Flutter publishable key and
   webhook endpoint must belong to the same Stripe account and mode.
2. **Webhook signature.** `stripe listen --print-secret` secret must match
   `STRIPE_WEBHOOK_SECRET`; re-verify after any CLI restart or endpoint change.
3. **Idempotency.** Replaying `payment_intent.succeeded`,
   `checkout.session.completed`, `refund.*` and dispute events must not double
   credit or double reverse.
4. **Out-of-order events.** `charge.refunded` arriving before
   `payment_intent.succeeded` must converge to the correct final state.
5. **Connect capabilities.** Seller creation must request both
   `configuration.merchant.capabilities.card_payments` and
   `stripe_balance.stripe_transfers`; check the capability fresh before any
   transfer.
6. **Transfers.** Use separate charges and transfers, deterministic transfer
   group, one allocation per order, exact integer-cent math, 10% fee, durable
   transfer/reversal IDs.
7. **Disputes.** Hold, reverse and release must be single-application and
   operator-visible.
8. **Payouts.** A Stripe transfer is not a bank payout; never label it as one.
9. **V2 account events.** Stripe v2 event destinations have their own signing
   secret, while the backend reads one `STRIPE_WEBHOOK_SECRET`. v1
   `account.updated` events were observed for the v2 account and are enough for
   basic status sync; if a v2 destination is added, add a second secret variable
   and verify both signatures instead of reusing one secret.

## 7. Defect handling

- File each failure with: scenario ID, environment, revision, expected/actual,
  artifact, provider IDs, severity, owner.
- P0/P1 failures block the release; fix at the shared seam and re-run the whole
  affected suite, not only the failing case.
- Keep a release ledger with date, scenario, result and artifact; do not mark a
  suite green from an older run after code or environment changes.

## 8. Current blockers and owner actions

| Blocker | Owner action | Unblocks |
|---|---|---|
| Live Stripe activation | Complete identity/business verification and activate products in the live dashboard | N1–N7 |
| `freebay.app` domain | Buy/configure DNS; then set `APP_URL`, `API_URL`, OAuth origins, webhook URL | Staging/live |
| Hosting accounts | Choose provider(s) and authorize access | Staging deploy |
| Resend domain | Verify `freebay.app` in Resend and change the from address | Emails to any user |
| Firebase/FCM | Create project + service account keys | J2–J5 |
| Apple Developer | Account, bundle ID, Sign in with Apple, Apple Pay | M2, A6 |
| Google Web OAuth | Create Web client and set `VITE_GOOGLE_WEB_CLIENT_ID` / `GOOGLE_WEB_CLIENT_ID` | Web Google login |
| Sentry | Create project and set DSNs | L5 |
| R2/S3 | Create bucket + keys; set `STORAGE_DRIVER=s3` | Durable media in staging |
| Open P0 issues | #3, #4, #25, #32, #33 and the parent #1/#2 gates | Release gate |
