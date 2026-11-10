---
name: browse-chrome
description: Use whenever driving Chrome through the browse MCP server (web UI checks, screenshots, evidence). Covers FreeBay web setup and the tab/viewport rules that prevent wrecking the user's browser.
---

# Browsing Chrome with browse

`browse` drives the user's real Chrome. Treat every tab as the user's tab: they are watching, and a mistake here is visible and annoying.

## Non-negotiables

- **Never call `page.setViewportSize()` on the user's page.** It emulates a smaller viewport inside their window and leaves a white band around the app; it looks like a broken layout and is not one. For responsive checks, open an isolated context (`browser.newContext({ viewport: { width, height } })`), screenshot there, then close it. If the tool only exposes `page`, take one viewport-agnostic screenshot and say so.
- **Never adopt or reuse a session you did not create.** Sessions like `stripe-setup` or `web-dev` belong to other work. Create your own with `session_new`, a name, and an allowlist of exactly the origins you need (`http://127.0.0.1:5173`).
- **Clean up.** `session_delete` your session when done; `session_reset` if you expect follow-up work. Close tabs you opened. Do not run `tabs_cleanup` with `idleMinutes: 0` unless the user asks.
- **Screenshots only inside the execute file roots.** Default root is `C:\Users\Qiyana\AppData\Local\Temp`; a repo path fails with `ExecuteFileAccessError`. Write to temp, then copy into `docs/test-runs/<date>/screenshots/` with the shell.
- **Relay first.** If `session_list` says the relay is unreachable, run `browse status`; start `browse serve` only when it reports `Relay: stopped`.
- Login, 2FA, passkey, captcha, payment: `handoff("what the user should do")` and wait. Never solve a challenge yourself.

## FreeBay web recipe

```bash
# fixture backend (browser-side fixtures live in the specs; this is the HTTP fallback)
cd web/e2e && PORT=3333 node fixture-backend.mjs

# app
cd web && BACKEND_URL=http://127.0.0.1:3333 npm run dev -- --port 5173 --strictPort
```

Then, in `execute`:

```js
await page.goto('http://127.0.0.1:5173/pt-BR/explore', { waitUntil: 'load' });
return { url: page.url(), h1: await page.locator('h1').allInnerTexts() };
```

Useful URLs: `/pt-BR` (marketing), `/pt-BR/explore`, `/pt-BR/categories`, `/pt-BR/products/web-fixture-camera`, `/pt-BR/products/does-not-exist` (error boundary). Authenticated account/checkout journeys need the browser fixture from `e2e/journeys/authenticated-contracts.spec.ts`; do not fake auth in the user's tab — use the Playwright spec instead.

## Loop

1. `snapshot()` before choosing anything; act through refs or accessible roles.
2. Verify with a fresh read (`page.url()`, heading, snapshot), not with the click's return value.
3. Record what you verified and what stayed test-only in `docs/test-runs/<date>/README.md`.

## What "working" means

A page rendering is not a passing journey. Report console errors, 404s from missing fixture endpoints (`/users/:id`, `/reviews/...`, `/auth/web/session/access-token`) as fixture gaps, and never claim a flow passed from a screenshot alone.
