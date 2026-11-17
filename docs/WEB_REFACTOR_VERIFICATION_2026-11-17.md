# Web refactor verification — 2026-11-17

Consolidated post-merge evidence for the web client refactor train (#45 feature boundaries, #46 app-shell
split, #47 marketplace split, #48 commerce correctness, #49 social typed cache, #50 session/auth fixes,
#51 chat lifecycle, #52 README diagram links). All eight PRs were reviewed and merged to `master` before
this pass; nothing here modifies production code.

This report is committed here because `.gitignore` keeps `docs/test-runs/` local ("Test/device evidence …
not durable docs"). The dated local copy (`docs/test-runs/2026-11-17/web-refactor-verification/REPORT.md`)
points back to this file, and the screenshots stay in the gitignored
`web/.e2e-real-artifacts/web-refactor-2026-11-17/`.

## Revision

| Item | Value |
|---|---|
| Commit verified | `bbf006a` — `Merge pull request #49 from vsmarlon/refactor/web-social-typed-cache-20261117` (detached HEAD, current `master` tip) |
| Baseline for comparison | `758f440` — pre-refactor tip recorded by the lead |
| Worktree | `wt/verify` (detached HEAD), sibling of the lead's main tree |

## Environment

| Item | Value |
|---|---|
| OS | Microsoft Windows 10 Home Single Language |
| Node / npm | v24.10.0 / 11.6.1 |
| Backend | **none**. No real NestJS, PostgreSQL, Redis, S3, Stripe, OAuth or email provider was used. |
| Web runtime under test | Vite dev server `127.0.0.1:5174` (React Router 7 dev) |
| API lane | `web/e2e/journeys/browser-fixture.ts` Playwright route mocks + `web/e2e/fixture-backend.mjs` (synthetic SSR responses) |
| Production build | `react-router build` (rolldown-vite 7.3.1) in `wt/verify/web` |
| Prepare | `npm ci --no-audit --no-fund` → `added 408 packages in 7s` |

This is **fixture-contract evidence only**. See [LIMITS](#limits).

## 1. CI record

### 1.1 Push runs on `master`

`gh run list --branch master --limit 8`:

| Run id | Merge | Conclusion | Duration |
|---|---|---|---|
| 44191677085 | #49 social typed cache (HEAD `bbf006a`) | **success** | 34s at first check, green on completion |
| 44190907549 | #52 README diagram links | success | 4m30s |
| 44190861781 | #47 marketplace split | **cancelled** | 25s |
| 44190764885 | #51 chat lifecycle | **cancelled** | 48s |
| 44190750238 | #50 session/auth | **cancelled** | 6s |
| 44190077455 | #48 commerce correctness | **cancelled** | 4m31s |
| 44190062860 | #46 app-shell split | **cancelled** | 6s |
| 44190042010 | #45 feature boundaries | **cancelled** | 15s |

The seven `cancelled` runs were **superseded, not failed**: `.github/workflows/ci.yml` declares
`concurrency: group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`, so each
new merge commit to `master` cancels the previous run on the same ref. The merges landed within minutes of
each other, leaving only the final run to finish.

The run that covers HEAD is complete and green (web lane included; the skipped jobs are path-filtered):

```
gh run view 44191677085
  head=bbf006a428612f16b203dc3a86503c849f96727f conclusion=success
  Detect changed areas = success
  Frontend Android debug APK = success
  Backend build, typecheck, lint, unit = success
  Web CI (React / TypeScript) = success
  Real web journey (Nest / PostgreSQL / Redis) = success
  Required CI quality gate = success
  (Real mobile journey, Backend integration and E2E, Frontend format/analyze = skipped by path filter)
```

The `#52` run (44190907549) succeeded but was README-only, so its `Web CI` job was skipped — it is not
web evidence.

### 1.2 Per-PR check rollups (authoritative pre-merge evidence)

`gh pr view <n>` for #45–#52: every PR head has **zero failed and zero cancelled checks**.

| PR | Head | State | Failing/cancelled checks |
|---|---|---|---|
| #45 | `fca6fd7` | MERGED | 0 of 9 |
| #46 | `3481383` | MERGED | 0 of 9 |
| #47 | `7dc65b7` | MERGED | 0 of 9 |
| #48 | `6dc206c` | MERGED | 0 of 9 |
| #49 | `9115f9f` | MERGED | 0 of 9 |
| #50 | `d9568cd` | MERGED | 0 of 9 |
| #51 | `a304b4a` | MERGED | 0 of 9 |
| #52 | `606cb51` | MERGED | 0 of 18 |

## 2. Production build and bundle comparison

```
cd wt/verify/web
npm run build
  ✓ built in 2.48s          (client)
  ✓ built in 649ms          (ssr environment)
  build/server/index.js   845.91 kB │ gzip: 174.33 kB
```

The baseline was **not** taken on faith: `git archive 758f440 web` was extracted to a temp directory,
`npm ci` + `npm run build` were run there, and it reproduced the lead's recorded client figures exactly
(same hashes for `entry.client-BZ1kptna.js`, `leaflet-src-*`, `chunk-OB3PAWPO-CT69Okjc.js`;
`detail` 14.08/4.71, `app-layout` 20.10/7.47, `thread` 79.67/27.61 all match). Sizes below are the
build's own printed kB (decimal).

### 2.1 Recorded chunks, before → after

| Chunk prefix | Baseline raw / gzip | HEAD raw / gzip | Δ raw | Verdict |
|---|---|---|---|---|
| entry.client | 215.01 / 67.27 | 215.01 / 67.27 | 0 | unchanged (identical hash) |
| leaflet-src | 148.80 / 43.37 | 148.80 / 43.37 | 0 | unchanged |
| chunk-OB3P | 132.38 / 43.66 | 132.38 / 43.66 | 0 | unchanged |
| pt-BR (catalog) | 80.44 / 19.34 | 80.59 / 19.38 | +0.15 | +0.19% |
| thread | 79.67 / 27.61 | 79.86 / 27.65 | +0.19 | +0.24% |
| esm | 41.26 / 12.89 | 41.26 / 12.89 | 0 | unchanged |
| post-card | 39.16 / 13.25 | 39.29 / 13.32 | +0.13 | +0.33% |
| components | 36.95 / 12.33 | 36.95 / 12.33 | 0 | unchanged |
| account | 24.99 / 9.26 | 24.99 / 9.26 | 0 | unchanged |
| useQuery | 22.95 / 7.65 | 22.95 / 7.65 | 0 | unchanged |
| use-debounced-value | 22.01 / 7.27 | 22.01 / 7.27 | 0 | unchanged |
| **app-layout** | 20.10 / 7.47 | **21.65 / 8.21** | **+1.55** | **+7.7% — flagged, explained** |
| marketing | 20.45 / 6.95 | 20.45 / 6.95 | 0 | unchanged |
| **detail** | 14.08 / 4.71 | **19.91 / 7.83** | **+5.83** | **+41.4% — flagged, explained** |
| order | 17.29 / 7.05 | 17.60 / 7.14 | +0.31 | +1.8% |
| editor | 15.27 / 6.50 | 15.27 / 6.51 | 0 | unchanged (gzip +0.01) |
| image-editor | 15.95 / 6.56 | 15.95 / 6.56 | 0 | unchanged |
| feed | 14.59 / 6.02 | 14.48 / 5.97 | −0.11 | −0.75% |
| root | 14.31 / 5.49 | 14.31 / 5.48 | 0 | unchanged |
| profile | 12.35 / 4.19 | 12.35 / 4.19 | 0 | unchanged |
| settings | 7.00 / 1.86 | 7.00 / 1.86 | 0 | unchanged |
| **queries** | — | **1.68 / 0.62** | **new** | **new chunk, small** |
| server/index.js | 844.84 / 173.84 (lead) · 842.25 / 172.97 (my rebuild of 758f440) | 845.91 / 174.33 | +1.07 vs lead · +3.66 vs my rebuild | +0.13% / +0.43% |

The server bundle embeds absolute build paths, so it is not byte-reproducible across directories; the
same-commit rebuild differed by 2.59 kB from the lead's recorded figure, which is the same order as the
observed change. Treat the server delta as within build-path noise.

### 2.2 Totals

Byte sums over `build/client/assets/*.js` (Vite's own decimal kB), both builds produced on this machine:

| Metric | Baseline | HEAD | Δ |
|---|---|---|---|
| Client JS files | 114 | 115 | +1 (`queries`) |
| Client JS raw | 1381.67 kB | 1392.24 kB | **+10.57 kB (+0.77%)** |
| Client JS gzip | 465.35 kB | 470.45 kB | **+5.10 kB (+1.10%)** |

Cross-check from the two build logs' printed tables: raw 1322.53 → 1332.89 kB (+10.36 kB), gzip
464.97 → 470.03 kB (+5.06 kB) — consistent with the byte sums.

### 2.3 Investigation of the flagged chunks

Intermediate builds (`git archive` copies, same `node_modules`) bracket each change to a single merge:

| Build point | `detail` | `app-layout` |
|---|---|---|
| `758f440` (baseline) | 14.08 | 20.10 |
| `47e6342` (merge #45) | 14.08 | 20.10 |
| `e217c1d` (merge #46) | 14.08 | **21.65** |
| `37668dd` (merge #47) | **19.91** | 21.65 |
| `bbf006a` (HEAD) | 19.91 | 21.65 |

`app-layout` +1.55 kB landed with **#46** (app-shell split: shell moved from `app/routes/app-layout.tsx`
into `app/components/app-shell/` — `index`, `sidebar`, `top-bar`, `bottom-nav`, `nav-items`,
`use-scroll-chrome`), i.e. new files with explicit exports replacing a single inline module.

`detail` +5.83 kB landed with **#47**, whose web diff is a net +121 lines in the marketplace slice
(`detail.tsx` −301 lines; `product-actions.tsx` +119, `use-product-actions.ts` +102, `seller-panel.tsx`
+78, `product-gallery.tsx` +32, `queries.ts` +48). Checks on what the extra bytes are:

* **Not duplicated framework code.** `Symbol.for('react.memo_cache_sentinel')` is the React Compiler's
  per-component memo-cache idiom; it is present in 60 chunks in **both** builds (e.g. `entry.client`,
  `components`, `marketing`). The baseline `detail` chunk had **0** occurrences because it held one large
  component; HEAD has **5**, matching the five extracted components now compiled separately in the route
  chunk.
* **Not duplicated markup.** Sliding every 80-character window over the HEAD `detail` chunk produced
  496 unique windows and **0** repeats.
* **Not code moved out of a shrunken chunk.** No chunk in the bundle shrank by ≥0.5 kB; the only chunk-name
  delta in either direction is the new 1.68 kB `queries` chunk (marketplace query keys/hooks now shared by
  the catalog and detail routes).
* Symbols only present in the HEAD `detail` chunk are `toggleFavorite`, `toggleFollow`, `queries`,
  `Symbol`, `memo_cache_sentinel` and chunk-id references — consistent with the extracted actions/hook
  layer, not with a stray copy of a page.

Conclusion: the grower is a **lazy route chunk** (+5.83 kB raw / +3.12 kB gzip) carrying the newly
extracted product-actions hook and the per-component compiler scaffolding. It is the single largest
relative change in the train; absolute cost is bounded because `detail` is only fetched on
`/products/:id`, and the whole client bundle grew 0.77% raw / 1.10% gzip. No new large chunk appeared.
Behavior-preserving is therefore true for *product* code, but not literally byte-preserving for two
route chunks — recorded here rather than assumed.

## 3. Journeys (owner-approved local runner)

Ports `5174`/`3333` were confirmed free (`Get-NetTCPConnection -State Listen -LocalPort 5173,5174,3333`
returned nothing) before the run. The `e2e/playwright.local.config.ts` webServer entries start
`node fixture-backend.mjs` (3333) and `npm run dev -- --port 5174 --strictPort`, so no dev server and no
real backend is touched.

```
cd wt/verify/web
npx playwright test --config=e2e/playwright.local.config.ts \
  e2e/journeys/public-marketplace.spec.ts e2e/journeys/authenticated-contracts.spec.ts
```

Exact result (exit code 0), run twice with identical outcomes (1.5m and 45.4s):

```
  ✓  11 [chromium] › e2e\journeys\authenticated-contracts.spec.ts:450:1 › profile edit, privacy step-up,
        deletion guard, notifications and close-friends state follow server outcomes (5.7s)
  ✓  12 [chromium] › e2e\journeys\public-marketplace.spec.ts:3:1 › public catalog and product metadata
        render in PT-BR without forwarding browser credentials (3.5s)
  ✓  13 [chromium] › e2e\journeys\public-marketplace.spec.ts:59:1 › marketing preferences support
        explicit light/dark themes and mobile reflow (736ms)

  1 skipped
  12 passed (1.5m)
```

The one skip is `authenticated-contracts.spec.ts:118:6` — `favorite and cart remain separate; cart
quantity is stock bounded and checkout uses session mode/server cents`. It is a pre-existing
`test.fixme` with the in-repo comment “CI-only hang in the cart route's session gate; the same journey
passes locally. Re-enable when RequireAuth/session refetch is fixed.” It was skipped before this train
and is not a train regression; it does mean cart/checkout is **not** covered by the journey lane.

## 4. Visual evidence

### 4.1 Mechanism

A temporary, uncommitted harness (`web/e2e/verify-evidence.capture.ts`) launches Playwright Chromium
(1440×900, `locale: pt-BR`, light theme), installs the same `installBrowserFixture(page, state)` mocks the
journeys use, opts out of the welcome overlay exactly as `openProtectedRoute` does, and writes full-page
screenshots. Output directory `web/.e2e-real-artifacts/web-refactor-2026-11-17/` is gitignored.

```
cd wt/verify/web
$env:E2E_BASE_URL='http://127.0.0.1:5174'
npx vite-node e2e/verify-evidence.capture.ts
  captured 01-app-shell-sidebar-expanded :: http://127.0.0.1:5174/pt-BR/explore
  captured 02-product-detail            :: http://127.0.0.1:5174/pt-BR/products/web-fixture-camera
  captured 03-social-feed-composer      :: http://127.0.0.1:5174/pt-BR/feed
  captured 04-orders                    :: http://127.0.0.1:5174/pt-BR/orders
  captured 05-marketing-landing         :: http://127.0.0.1:5174/pt-BR
```

### 4.2 Inventory

Screenshots stay in the gitignored folder (not committed); paths relative to `wt/verify/web/`:

| File | Surface | Verified visually |
|---|---|---|
| `.e2e-real-artifacts/web-refactor-2026-11-17/01-app-shell-sidebar-expanded.png` | `/pt-BR/explore` with `AppShell` sidebar expanded | sidebar (Início, Explorar, Vender, Mensagens, Perfil, Carteira, Configurações) + collapse control, top bar (search, notifications, account menu, theme, EN/PT-BR), catalog heading, filter row, product card |
| `…/02-product-detail.png` | `/pt-BR/products/web-fixture-camera` (#47 surface) | gallery pane with `Câmera analógica, imagem 1` label, title/condition/price/stock, description, seller panel (avatar initials `PD`, verified check, `São Paulo, SP`), ratings `4.8 / 5 · 6 avaliações`, quantity stepper, action row (cart, favorite, contact, follow), primary CTA |
| `…/03-social-feed-composer.png` | `/pt-BR/feed` (#49 surface) | Explorar/Seguindo tabs, Todos/Publicações/Produtos filters, composer (placeholder, audience select `Todos`, attach, `Publicar` in disabled state), post card with author/date/engagement counts, right rail (Stories, Buscar publicações, saved/liked/mine links) |
| `…/04-orders.png` | `/pt-BR/orders` (#48 surface) | `Minhas compras` heading, commerce tabs (Seu carrinho, Minhas compras, Minhas vendas, Carteira, Disputas), status filter with all status options — **list body stays in loading skeletons**, see F2 |
| `…/05-marketing-landing.png` | `/pt-BR` marketing landing | hero, aurora background, search field, primary/secondary CTAs, sticker collage, “Mais que um anúncio” panel, footer |

### 4.3 Design review against `web/DESIGN.md` (tokens from `frontend/DESIGN.md`)

Consistent with the contract: square geometry everywhere (global `border-radius: 0`), Space Grotesk
display headings over Inter body, tonal light surface cards on the aurora canvas, magenta reserved for
action/focus (active tab, search button, CTAs, focus rings), 1.5–2 px ink/edge borders and hard offset
shadows on primary buttons, PT-BR copy complete on every surface, and the shell/sidebar reflow intact
after the #46 split.

Findings, in severity order:

**F1 — Primary CTA *links* render label ink-on-magenta (contrast ≈1.7–2.3:1). Pre-existing, not from this train.**
Computed style of the product-detail CTA: class list contains `text-white`, computed `color:
rgb(17, 16, 14)` (= `--ink #11100E`) over `linear-gradient(#660062 → #8A1083)`. Measured contrast:
1.72:1 on the dark stop, 2.25:1 on the magenta stop (WCAG AA needs 4.5:1; white would be 8.46:1).
Cause: `app/styles.css` declares unlayered `a { color: inherit }` (line 82), and unlayered CSS beats
Tailwind 4's `@layer utilities`, so `text-white`/`text-brand` on any `<a>` loses. Blast radius from
source: every `buttonClass('primary')` anchor — `product-actions.tsx:93` (`Comprar agora`), `cart.tsx:143`,
`my-products.tsx:59`, `buy.tsx:281`, `post-card.tsx:55`, `post.tsx:141/271`, plus `app/routes/marketing.tsx`
(`Começar`, `Explorar Freebay` — confirmed dark by DOM probe). `button` elements are unaffected, which is
why the search button looks correct.
Status: `styles.css`, `marketing.tsx` and this markup pattern are **unchanged** by #45–#52 (empty
`git diff 758f440..HEAD -- web/app/styles.css web/app/routes/marketing.tsx`, and `758f440`'s
`detail.tsx` already used `<Link className={buttonClass('primary')}>`). Recorded as an existing
design-contract violation surfaced by the evidence pass, **not** a refactor regression.

**F2 — The order list is not verifiable in this lane; the fixture has a dead `/orders` handler.**
`04-orders.png` shows chrome + filter but the list stays in loading skeletons at 1.5 s and again at 4.5 s.
The intercepted-call log for that visit contains only `POST /auth/web/session/access-token` (×2) and
`GET /users/me` — **no `/orders/*` request ever reached the fixture**. Root cause is in the fixture
itself: `browser-fixture.ts` routes only paths starting with `/auth/`, `/users`, `/products`,
`/categories`, `/favorites`, `/cart`, `/social`, `/stories`, `/chat`, `/notifications`, `/media` or equal
to `/reports`; everything else falls through to `route.continue()`. `/orders` is missing from that
allow-list, so the perfectly good `/orders/my/purchases` handler at line 381 is unreachable and the
request is proxied to the fixture backend, which answers 404. Consequence: neither this pass nor the CI
journeys exercise the purchases/sales list. I did not determine whether the stuck skeleton is TanStack's
disabled-query pending state or a session gate; that needs the owner of #48/#50, and I made no code change.

**F3 — Stories rail shows an error state (`Não foi possível carregar os stories`).** Fixture lane artifact:
`browser-fixture.ts` serves `/stories/user/:id` and `/stories/:id/view` but not the request the rail makes,
so it renders its error + retry affordance. Not a design-contract violation; the error state itself is
readable and on-token.

**F4 — Product imagery not visually verified.** `images.example.invalid` is aborted by the fixture
(non-origin host), and `/media/*` requires the view-once opening header, so gallery and card images render
as broken-image placeholders. Layout around them (aspect box, label, gallery arrows) is verified; pixel
content is not.

## 5. Diff totals (`758f440..HEAD`, web only)

```
git diff 758f440..HEAD --stat -- web | tail -n 3
 51 files changed, 2339 insertions(+), 1204 deletions(-)
```

Breakdown by top-level area under `web/app/`: 37 files in `features/`, 8 in `components/`, 3 in `core/`
(plus `web/eslint.config.js`, route manifests and tests).

## Limits

* **Fixture contract only.** Every runtime claim above comes from mocked HTTP with synthetic DTOs. No real
  NestJS, PostgreSQL, Redis, Stripe, OAuth, email, object storage, or socket server participated. Nothing
  here proves production runtime behavior, backend authorization, price/inventory authority, or provider
  integration.
* **No live sockets.** The socket-handshake reduction described in #51 is source-level reasoning about
  subscription/teardown paths; it is **not** a timing or connection-count measurement, and no live
  WebSocket server was involved.
* **No runtime performance measured.** The only performance figures are bundle bytes (section 2). No LCP,
  INP, CLS, frame timing, memory, or device profiling was performed.
* **No real-device evidence.** Flutter/Android surfaces are out of scope; the "Frontend Android debug APK"
  job in section 1.1 is CI's own result, not a device run from this pass.
* **Cart/checkout journey still skipped** (pre-existing `test.fixme`, section 3), and the order list is
  fixture-unreachable (F2) — commerce list/detail rendering is therefore not visually verified.
* **Screenshots are dev-server renders**, not the production bundle. Build-path-dependent output
  (`build/server/index.js`) is not byte-reproducible across directories, as noted in 2.1.
* **The evidence harness is uncommitted by design**: `web/e2e/verify-evidence.capture.ts` stays in the
  worktree; screenshots stay in the gitignored `.e2e-real-artifacts/` folder and are referenced here by
  path only.
