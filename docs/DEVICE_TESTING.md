# FreeBay — Device Testing (mobile-mcp)

How to drive the app on a **real device/emulator** and verify core flows with mobile-mcp.
Tool table and tap scripts live in `.agents/skills/freebay-mobile-mcp/SKILL.md`; verification
commands live in `AGENTS.md`. This file is only the device loop.

## 1. Backend up
```
# Use native/external PostgreSQL :5432 and Redis :6379 processes.
# Docker is not part of the device-testing protocol.
cd nest-backend && npm run start:dev   # API on :3000, health at GET /health
npm run db:seed   # demo catalog + users
```
Seed users exist for browsing (e.g. `carlos.silva@email.com`); the shared seed password is
not committed — for authed flows **register a fresh account in-app** (Flow A covers it).

## 2. Point the app at your machine
Physical device and emulator cannot reach `localhost` — it means the phone itself.
Default dev URL is `http://localhost:3000`, which works over USB/emulator via:
```
adb reverse tcp:3000 tcp:3000
fvm flutter run
```
Only Wi-Fi debugging (no USB) needs the machine's current LAN IP:
```
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:3000
```
`kReleaseMode` throws if `API_BASE_URL` is missing.

## 3. Build → install → launch
```
flutter build apk --debug     # build/app/outputs/flutter-apk/app-debug.apk
```
- `mobile_list_available_devices` → pick the device id
- `mobile_install_app` with the apk path above
- `mobile_launch_app` with `packageName: com.freebay.app` on both platforms (Q13 landed 2026-09-06). Confirm with `applicationId` in `frontend/android/app/build.gradle.kts` and `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project.

## 4. Selector policy
`mobile_list_elements_on_screen` returns the accessibility tree. Today it exposes only rendered
text, so address controls by **visible PT label** (e.g. `Entrar`, `Explorar`, `Finalizar Compra`)
and tap icon-only controls (bottom nav, like, back, avatar) by **element center coordinates** —
brittle across screen sizes. Once `Semantics(identifier:)` lands (Q20) prefer stable ids:
`nav_feed|explore|wallet|chat|profile`, `auth_email|password|submit`, `product_buy|add_to_cart`,
`checkout_pay`, `chat_input|send`, `wallet_connect_onboard`, `drawer_toggle`.

## Current production-hardening checkpoint

No device result is claimed yet. Run the matrix below on a fresh authenticated
session where required, using package `com.freebay.app`. For every scenario, capture
a screenshot where safe, logs/request counts, a crash check, pass/fail, and the
artifact path. Store artifacts under `docs/device-runs/<date>/`; redact personal
data. Never capture email, token, precise location, Stripe secrets, or other
personal data in screenshots or logs.

| Issue | Exact device scenarios |
|---|---|
| #3 | Valid order creation parses; unavailable/out-of-stock is controlled; when safely inducible, failure leaves no partial stock/order. |
| #4 | New user shows zero/empty; failure/retry; logout and A→B show no stale wallet. |
| #25 | Auth email is prefilled; edits survive rebuild; whitespace/empty uses fallback; A→B resets; redact email from screenshots/logs. |
| #6 | `/welcome` is the sole consent owner: decline/native cancel/no biometrics/cold boot/logout/expiry/A→B show no unauthorized prompt; Settings later supports opt-in/out. |
| #13 | Record request counts: drag = 0, cancel/dismiss = 0, Apply = 1; full range sends no filter. |
| #14 | Scroll categories vertically, tap a category, tap a product, swipe the parent outside the panel; destinations stay unchanged. |
| #22 | Profile pagination appends with stable scroll, reaches terminal, fails/retries on the same page, and adds no duplicates. |
| #23 | Saved-post pagination; successful unsave removes immediately; failed unsave remains for retry; refresh/reopen and auth isolation hold. |
| #27 | Following shows only followed authors; content-filter reset; follow/unfollow removes stale rows; append/retry has no duplicates. |
| #26 | Duplicate publish tap makes one request; failure shows no false story; success appears once in global and user stories; reopen; retain backend/log cleanup proof where safe. |
| #28 | Vendas All/status values; seller isolation; load-more/retry/empty/terminal; Meus produtos remains separate. |
| #24 | Exact editable unsent draft; Back sends none; edited explicit send once; reopen the same product; different products stay distinct; counterpart/product summaries are correct. |
| #30 | Disabled/denied/denied-forever send nothing; retry after a fresh measured fix; show provider accuracy; confirm once; sender/recipient/reload retain one canonical message; failed map launch does not crash; UTC timestamps display in device-local time; push preview has no coordinates. |
| #32 | Wallet renders onboarding-required, requirements-due, restricted, and transfer-ready distinctly; hosted onboarding return/refreshes authoritative state; retry/logout/A→B have no stale state; Express Dashboard wording never claims a bank payout. Verify the configured return URI actually opens `com.freebay.app`. |
| #33 | With Stripe test mode and backend logs, delivery creates one seller transfer per allocation; retry/restart creates no duplicate; multi-seller amounts retain the exact 10% integer-cent fee; full refund/lost dispute performs one reversal; operator failure rows expose state/attempt/provider/error. Device UI alone is insufficient evidence. |
| UI follow-ups | Light text remains readable while the animated aurora is visible; authenticated/guest Profile inherit `aurora.frag`; active chat rows show name/product/preview/time/unread count; product-chat composer trims/disables/retries; every post comment/reply has fine tonal top/bottom separation. |

Execution order: set up backend/adb, discover the device and foreground app, and
inspect elements after every screen change. Create fresh accounts A/B, then run
#6, #13, #14, the UI follow-ups, #24, #4, #25, #22, #23, #27, #26, #28, #30,
#32, #3, and #33. Keep destructive, payment, and data-dependent checks last. Collect
logs/crashes and update `FREEBAY_RELEASE_HANDOFF.md` with each artifact and result.
Further mobile-MCP use is intentionally deferred until Flutter is running for this
final matrix.

## 5. Flows (`action → expected`)
**A. Auth** — open app → register (email/password) → `/feed`. Logout via drawer → `/login`.
Guest button → read-only feed; tapping Buy/Like → login sheet, then returns to same screen.

**B. Shell nav** — swipe left/right across feed↔explore↔wallet↔chat↔profile (finger-tracked, no
wrong-direction jump); at feed, over-swipe right → drawer opens continuously; bottom nav taps match.

**C. Buy** — explore → set radius/category filter → open product → Buy/Add to cart → checkout →
Stripe PaymentSheet → success only after backend confirms (not on sheet dismiss).

**D. Chat** — open conversation → send → bubble reconciles to a real id (no dupes on double-send);
kill wifi, send, restore → message flushes once; received messages appear live.

**E. Wallet** — balance shows available/pending; statement rows come from the ledger and carry a
reason label; "CONFIGURAR RECEBIMENTOS" opens the Stripe hosted onboarding; once the account can
receive transfers the button becomes "ABRIR PAINEL DE PAGAMENTOS" and opens the Express dashboard.
There is no in-app withdraw form — Stripe pays the seller out on its own schedule.

**F. Push + deep link** — background app, trigger a push, tap it → routes to the target screen
(foreground / background / terminated). Cold-start a `freebay://` (later https) link → same target.

## 6. Evidence
- `mobile_take_screenshot` at each `expected`; name `flow<A-F>_<step>_<pass|fail>.png` under `docs/device-runs/<date>/`.
- Run `mobile_list_crashes` after every flow; a non-empty result fails the flow.
- Pass = every step's expected observed AND crashes empty.

## 7. Profile-mode performance fixtures

Use the same seeded backend and device model/OS for each baseline and comparison;
connect the device to the backend (e.g. `adb reverse tcp:3000 tcp:3000`),
unlock it and leave its screen awake. A locked Android device can hold session
hydration in a native biometric prompt; a connected device alone is not enough.
`feed_scroll` needs multiple real posts; `explore_scroll` needs at least four
products; `product_detail` measures opening the first real product from Explore;
`chat_scroll` needs an already signed-in account with a long existing real
conversation; `story_view` needs a signed-in session and an image story with
media loaded. The perf test
fails explicitly when the target content or scroll extent is absent. Run
`node scripts/perf-check.js <flow> --device <id> --update-baseline` to record
the first **measured** baseline, then without that flag for the regression gate.
Reports live in `docs/test-runs/<date>/perf-<flow>.md`; see `freebay-perf`.
