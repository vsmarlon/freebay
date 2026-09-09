# FreeBay — Device Testing (mobile-mcp)

How to drive the app on a **real device/emulator** and verify core flows with mobile-mcp.
Tool table and tap scripts live in `.agents/skills/freebay-mobile-mcp/SKILL.md`; verification
commands live in `AGENTS.md`. This file is only the device loop.

## 1. Backend up
```
# PostgreSQL :5432 and Redis :6379 must already be available.
cd nest-backend && npm run start:dev   # API on :3000, health at GET /health
psql "$DATABASE_URL" -f db/seeds/001_seed_dev.sql   # demo catalog + users
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
- `mobile_launch_app` appId — **`com.freebay.app`** on both platforms (Q13 landed 2026-09-06). Confirm with `applicationId` in `frontend/android/app/build.gradle.kts` and `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project.

## 4. Selector policy
`mobile_list_elements_on_screen` returns the accessibility tree. Today it exposes only rendered
text, so address controls by **visible PT label** (e.g. `Entrar`, `Explorar`, `Finalizar Compra`)
and tap icon-only controls (bottom nav, like, back, avatar) by **element center coordinates** —
brittle across screen sizes. Once `Semantics(identifier:)` lands (Q20) prefer stable ids:
`nav_feed|explore|wallet|chat|profile`, `auth_email|password|submit`, `product_buy|add_to_cart`,
`checkout_pay`, `chat_input|send`, `wallet_withdraw|connect_onboard`, `drawer_toggle`.

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
